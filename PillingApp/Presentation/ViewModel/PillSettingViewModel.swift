//
//  PillSettingViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - PillSettingViewModel

final class PillSettingViewModel {
    
    struct Input {
        let pillTypeButtonTapped: AnyObserver<Void>
        let startDateButtonTapped: AnyObserver<Void>
        let dateSelected: AnyObserver<Date>
        let pillInfoSelected: AnyObserver<PillInfo>
        let nextButtonTapped: AnyObserver<Void>
    }
    
    struct Output {
        let selectedPillTypeText: Driver<String?>
        let selectedStartDateText: Driver<String?>
        let isNextButtonEnabled: Driver<Bool>
        let presentDatePicker: Signal<Void>
        let presentPillTypePicker: Signal<Void>
        let proceed: Signal<Void>
        let alertMessage: Signal<String>
    }
    
    // MARK: - Properties
    
    let input: Input
    let output: Output
    
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let timeProvider: TimeProvider
    private let pillTypeButtonTappedSubject = PublishSubject<Void>()
    private let startDateButtonTappedSubject = PublishSubject<Void>()
    private let dateSelectedSubject = PublishSubject<Date>()
    private let pillInfoSelectedSubject = PublishSubject<PillInfo>()
    private let nextButtonTappedSubject = PublishSubject<Void>()
    private let alertMessageSubject = PublishSubject<String>()
    
    private let selectedPillInfoRelay = BehaviorRelay<PillInfo?>(value: nil)
    private let selectedStartDateRelay = BehaviorRelay<Date?>(value: nil)
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init(userDefaultsManager: UserDefaultsManagerProtocol, timeProvider: TimeProvider = SystemTimeProvider()) {
        self.userDefaultsManager = userDefaultsManager
        self.timeProvider = timeProvider
        
        // Input 초기화
        self.input = Input(
            pillTypeButtonTapped: pillTypeButtonTappedSubject.asObserver(),
            startDateButtonTapped: startDateButtonTappedSubject.asObserver(),
            dateSelected: dateSelectedSubject.asObserver(),
            pillInfoSelected: pillInfoSelectedSubject.asObserver(),
            nextButtonTapped: nextButtonTappedSubject.asObserver()
        )
        
        // Output에 필요한 Observable 생성
        let isNextButtonEnabled = Observable
            .combineLatest(
                selectedPillInfoRelay.asObservable(),
                selectedStartDateRelay.asObservable()
            )
            .map { pillInfo, startDate in
                guard let info = pillInfo, let _ = startDate else { return false }
                return (info.takingDays + info.breakDays) <= 28
            }
        
        let selectedPillTypeText = selectedPillInfoRelay
            .map { pillInfo -> String? in
                guard let info = pillInfo else { return nil }
                return "\(info.name) (복용 \(info.takingDays)일 / 휴약 \(info.breakDays)일)"
            }
        
        let selectedStartDateText = selectedStartDateRelay
            .map { date -> String? in
                guard let date = date else { return nil }
                // Use a local helper that relies only on timeProvider to avoid capturing self
                let dateText = timeProvider.format(date, style: .monthDay)
                let cal = timeProvider.calendar
                let todayStart = timeProvider.startOfDay(for: timeProvider.now)
                let selectedStart = timeProvider.startOfDay(for: date)
                if selectedStart < todayStart {
                    let days = {
                        let cal = timeProvider.calendar
                        let today = timeProvider.startOfDay(for: timeProvider.now)
                        let start = timeProvider.startOfDay(for: date)
                        let diff = cal.dateComponents([.day], from: start, to: today).day ?? 0
                        return diff + 1
                    }()
                    return "\(dateText) (\(days)일째)"
                } else if cal.isDate(selectedStart, inSameDayAs: todayStart) {
                    return "\(dateText) (오늘)"
                } else {
                    let remain = cal.dateComponents([.day], from: todayStart, to: selectedStart).day ?? 0
                    return "\(dateText) (\(remain)일 남음)"
                }
            }
        
        // userDefaultsManager를 캡처하여 사용
        let proceed = nextButtonTappedSubject
            .withLatestFrom(
                Observable.combineLatest(
                    selectedPillInfoRelay.asObservable(),
                    selectedStartDateRelay.asObservable()
                )
            )
            .compactMap { pillInfo, startDate -> (PillInfo, Date)? in
                guard let pillInfo = pillInfo, let startDate = startDate else {
                    return nil
                }
                return (pillInfo, startDate)
            }
            .filter { pillInfo, _ in (pillInfo.takingDays + pillInfo.breakDays) <= 28 }
            .do(onNext: { [userDefaultsManager] pillInfo, startDate in
                userDefaultsManager.savePillInfo(pillInfo)
                userDefaultsManager.savePillStartDate(startDate)
            })
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
        
        // Output 초기화
        self.output = Output(
            selectedPillTypeText: selectedPillTypeText.asDriver(onErrorJustReturn: nil),
            selectedStartDateText: selectedStartDateText.asDriver(onErrorJustReturn: nil),
            isNextButtonEnabled: isNextButtonEnabled.asDriver(onErrorJustReturn: false),
            presentDatePicker: startDateButtonTappedSubject.asSignal(onErrorSignalWith: .empty()),
            presentPillTypePicker: pillTypeButtonTappedSubject.asSignal(onErrorSignalWith: .empty()),
            proceed: proceed,
            alertMessage: alertMessageSubject.asSignal(onErrorSignalWith: .empty())
        )
        
        // 바인딩
        bindActions()
    }
    
    // MARK: - Bind
    
    private func bindActions() {
        pillInfoSelectedSubject
            .subscribe(onNext: { [weak self] pillInfo in
                let total = pillInfo.takingDays + pillInfo.breakDays
                if total <= 28 {
                    self?.selectedPillInfoRelay.accept(pillInfo)
                } else {
                    self?.alertMessageSubject.onNext("복용일과 휴약일의 합은 28일 이하여야 해요.")
                }
            })
            .disposed(by: disposeBag)
        
        dateSelectedSubject
            .subscribe(onNext: { [weak self] date in
                self?.selectedStartDateRelay.accept(date)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private func calculateDaysSinceStart(from startDate: Date) -> Int {
        let cal = timeProvider.calendar
        let today = timeProvider.startOfDay(for: timeProvider.now)
        let start = timeProvider.startOfDay(for: startDate)
        let days = cal.dateComponents([.day], from: start, to: today).day ?? 0
        return days + 1 // 1일차부터
    }

    private func formatDateWithDayInfo(date: Date) -> String {
        let dateText = timeProvider.format(date, style: .monthDay) // "M월 d일"
        let cal = timeProvider.calendar

        let todayStart = timeProvider.startOfDay(for: timeProvider.now)
        let selectedStart = timeProvider.startOfDay(for: date)

        if selectedStart < todayStart {
            let days = calculateDaysSinceStart(from: date)
            return "\(dateText) (\(days)일째)"
        } else if cal.isDate(selectedStart, inSameDayAs: todayStart) {
            return "\(dateText) (오늘)"
        } else {
            let remain = cal.dateComponents([.day], from: todayStart, to: selectedStart).day ?? 0
            return "\(dateText) (\(remain)일 남음)"
        }
    }
}

