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
    }
    
    // MARK: - Properties
    
    let input: Input
    let output: Output
    
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    private let pillTypeButtonTappedSubject = PublishSubject<Void>()
    private let startDateButtonTappedSubject = PublishSubject<Void>()
    private let dateSelectedSubject = PublishSubject<Date>()
    private let pillInfoSelectedSubject = PublishSubject<PillInfo>()
    private let nextButtonTappedSubject = PublishSubject<Void>()
    
    private let selectedPillInfoRelay = BehaviorRelay<PillInfo?>(value: nil)
    private let selectedStartDateRelay = BehaviorRelay<Date?>(value: nil)
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM월 dd일"
        return formatter
    }()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init(userDefaultsManager: UserDefaultsManagerProtocol) {
        self.userDefaultsManager = userDefaultsManager
        
        // Output에 필요한 Observable 먼저 생성
        let isNextButtonEnabled = Observable
            .combineLatest(
                selectedPillInfoRelay.asObservable(),
                selectedStartDateRelay.asObservable()
            )
            .map { pillInfo, startDate in
                pillInfo != nil && startDate != nil
            }
        
        let selectedPillTypeText = selectedPillInfoRelay
            .map { pillInfo -> String? in
                guard let info = pillInfo else { return nil }
                return "\(info.name) (복용 \(info.takingDays)일 / 휴약 \(info.breakDays)일)"
            }
        
        let selectedStartDateText = selectedStartDateRelay
            .map { date -> String? in
                guard let date = date else { return nil }
                return PillSettingViewModel.formatDateWithDayInfo(date: date)
            }
        
        // Avoid capturing self before initialization by using a local handler
        let saveHandler: (PillInfo, Date) -> Void = { [userDefaultsManager] pillInfo, startDate in
            // Call a static helper to persist without touching self
            PillSettingViewModel.savePillSettings(pillInfo: pillInfo, startDate: startDate, using: userDefaultsManager)
        }
        
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
            .do(onNext: { pillInfo, startDate in
                saveHandler(pillInfo, startDate)
            })
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
        
        // Input 초기화
        self.input = Input(
            pillTypeButtonTapped: pillTypeButtonTappedSubject.asObserver(),
            startDateButtonTapped: startDateButtonTappedSubject.asObserver(),
            dateSelected: dateSelectedSubject.asObserver(),
            pillInfoSelected: pillInfoSelectedSubject.asObserver(),
            nextButtonTapped: nextButtonTappedSubject.asObserver()
        )
        
        // Output 초기화
        self.output = Output(
            selectedPillTypeText: selectedPillTypeText.asDriver(onErrorJustReturn: nil),
            selectedStartDateText: selectedStartDateText.asDriver(onErrorJustReturn: nil),
            isNextButtonEnabled: isNextButtonEnabled.asDriver(onErrorJustReturn: false),
            presentDatePicker: startDateButtonTappedSubject.asSignal(onErrorSignalWith: .empty()),
            presentPillTypePicker: pillTypeButtonTappedSubject.asSignal(onErrorSignalWith: .empty()),
            proceed: proceed
        )
        
        // 바인딩
        bindActions()
    }
    
    // MARK: - Bind
    
    private func bindActions() {
        pillInfoSelectedSubject
            .subscribe(onNext: { [weak self] pillInfo in
                self?.selectedPillInfoRelay.accept(pillInfo)
            })
            .disposed(by: disposeBag)
        
        dateSelectedSubject
            .subscribe(onNext: { [weak self] date in
                self?.selectedStartDateRelay.accept(date)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private static func savePillSettings(pillInfo: PillInfo, startDate: Date, using manager: UserDefaultsManagerProtocol) {
        manager.savePillInfo(pillInfo)
        manager.savePillStartDate(startDate)
    }
    
    private func savePillSettings(pillInfo: PillInfo, startDate: Date) {
        userDefaultsManager.savePillInfo(pillInfo)
        userDefaultsManager.savePillStartDate(startDate)
    }
    
    private static func calculateDaysSinceStart(from startDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: Date())
        return (components.day ?? 0) + 1 // 1일차부터 시작
    }
    
    private static func formatDateWithDayInfo(date: Date) -> String {
        let dateText = dateFormatter.string(from: date)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        if selectedDay < today {
            let days = calculateDaysSinceStart(from: date)
            return "\(dateText) (\(days)일째)"
        } else if selectedDay == today {
            return "\(dateText) (오늘)"
        } else {
            let components = calendar.dateComponents([.day], from: today, to: selectedDay)
            let daysRemaining = components.day ?? 0
            return "\(dateText) (\(daysRemaining)일 남음)"
        }
    }
}

