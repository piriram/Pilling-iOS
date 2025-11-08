//
//  DashboardSheetViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/7/25.
//
import Foundation
import RxSwift
import RxCocoa

// MARK: - ViewModel (no protocol, MVVM I/O)

final class DefaultDashboardSheetViewModel {

    // MARK: Input/Output

    struct Input {
        let viewDidAppear: Observable<Void>
        let tapNotTaken: Observable<Void>
        let tapTaken: Observable<Void>
        let tapTakenDouble: Observable<Void>
        let memoText: Observable<String>
        let requestDismiss: Observable<Void> // 딤드 탭/스와이프 등
    }

    struct Output {
        let selectedIndex: Driver<Int?>            // -1 or 0/1/2
        let isMemoPlaceholderHidden: Driver<Bool>  // true면 placeholder 숨김
        let shouldShowSheet: Signal<Void>
        let dismiss: Signal<(PillStatus?, String)>  // status가 nil이면 메모만 저장
    }

    // MARK: State

    private let selectedDate: Date
    private let disposeBag = DisposeBag()

    private let currentMemo = BehaviorRelay<String>(value: "")
    private let currentSelectedIndex = BehaviorRelay<Int?>(value: nil)
    private let lastResolvedStatus = BehaviorRelay<PillStatus?>(value: nil)

    // MARK: Init

    init(selectedDate: Date, initialMemo: String = "", initialStatus: PillStatus? = nil) {
        self.selectedDate = selectedDate
        currentMemo.accept(initialMemo)

        if let status = initialStatus {
            let tag = Self.tag(for: status)
            currentSelectedIndex.accept(tag >= 0 ? tag : nil)
            lastResolvedStatus.accept(status)
        }
    }

    // MARK: Transform

    func transform(_ input: Input) -> Output {
        // 메모
        input.memoText
            .bind(to: currentMemo)
            .disposed(by: disposeBag)

        // 버튼 탭 → tag + PillStatus 계산
        let notTakenSelected = input.tapNotTaken
            .map { 0 }
            .share()

        let takenSelected = input.tapTaken
            .map { 1 }
            .share()

        let takenDoubleSelected = input.tapTakenDouble
            .map { 2 }
            .share()

        let selectedTag = Observable.merge(notTakenSelected, takenSelected, takenDoubleSelected)
            .do(onNext: { [weak self] tag in self?.currentSelectedIndex.accept(tag) })
            .share()

        let statusFromTag = selectedTag
            .map { [weak self] tag -> PillStatus in
                guard let self else { return .scheduled }
                return self.resolveStatus(forTag: tag)
            }
            .do(onNext: { [weak self] status in self?.lastResolvedStatus.accept(status) })
            .share()

        // 버튼 탭 시 즉시 dismiss 이벤트 발생
        let dismissOnTap = statusFromTag
            .withLatestFrom(currentMemo.asObservable()) { ($0 as PillStatus?, $1) }
            .asSignal(onErrorSignalWith: .empty())

        // requestDismiss 시 선택값이 있으면 그걸로, 없으면 메모만 저장
        let dismissOnRequest = input.requestDismiss
            .withLatestFrom(Observable.combineLatest(lastResolvedStatus.asObservable(),
                                                     currentMemo.asObservable()))
            .map { [weak self] (statusOpt, memo) -> (PillStatus?, String) in
                guard let self = self else { return (nil, memo) }
                // 상태 버튼을 눌렀으면 선택된 상태 사용
                if let status = statusOpt {
                    return (status, memo)
                }
                // 버튼을 누르지 않았으면 상태는 nil, 메모만 저장
                return (nil, memo)
            }
            .asSignal(onErrorSignalWith: .empty())

        // 출력 구성
        let output = Output(
            selectedIndex: currentSelectedIndex
                .asDriver(onErrorJustReturn: nil),
            isMemoPlaceholderHidden: currentMemo
                .map { !$0.isEmpty }
                .asDriver(onErrorJustReturn: true),
            shouldShowSheet: input.viewDidAppear
                .asSignal(onErrorSignalWith: .empty()),
            dismiss: Signal.merge(dismissOnTap, dismissOnRequest)
        )

        return output
    }

    // MARK: Helpers

    private func resolveStatus(forTag tag: Int) -> PillStatus {
        switch tag {
        case 0:
            let cal = Calendar.current
            let isToday = cal.isDateInToday(selectedDate)
            let isInPast = selectedDate < cal.startOfDay(for: Date())
            return isToday ? .scheduled : (isInPast ? .missed : .todayNotTaken)
        case 1:
            return .taken
        case 2:
            return .takenDouble
        default:
            return .scheduled
        }
    }

    private func fallbackStatus() -> PillStatus {
        let cal = Calendar.current
        let isToday = cal.isDateInToday(selectedDate)
        let isInPast = selectedDate < cal.startOfDay(for: Date())
        return isToday ? .scheduled : (isInPast ? .missed : .scheduled)
    }

    private static func tag(for status: PillStatus) -> Int {
        switch status {
        case .missed, .scheduled, .todayNotTaken, .todayDelayed, .todayDelayedCritical:
            return 0
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed, .todayTakenTooEarly, .takenTooEarly:
            return 1
        case .takenDouble:
            return 2
        case .rest:
            return -1
        }
    }
}
