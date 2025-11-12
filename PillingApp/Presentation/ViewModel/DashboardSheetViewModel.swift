//
//  DashboardSheetViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 11/12/25.
//

import Foundation
import RxSwift
import RxCocoa

protocol DashboardSheetViewModel {
    func transform(_ input: DashboardSheetViewModelInput) -> DashboardSheetViewModelOutput
}

struct DashboardSheetViewModelInput {
    let viewDidAppear: Observable<Void>
    let tapNotTaken: Observable<Void>
    let tapTaken: Observable<Void>
    let tapTakenDouble: Observable<Void>
    let memoText: Observable<String>
    let requestDismiss: Observable<Void>
    let timeChanged: Observable<Date>
}

struct DashboardSheetViewModelOutput {
    let shouldShowSheet: Signal<Void>
    let initialButtonTag: Driver<StatusButtonTag>
    let formattedTime: Driver<String>
    let isMemoPlaceholderHidden: Driver<Bool>
    let dismiss: Signal<(PillStatus?, String)>
}

final class DefaultDashboardSheetViewModel: DashboardSheetViewModel {
    
    private let selectedDate: Date
    private let initialMemo: String
    private let initialStatus: PillStatus?
    private let takenAt: Date?
    
    private var selectedStatus: PillStatus?
    
    init(
        selectedDate: Date,
        initialMemo: String,
        initialStatus: PillStatus?,
        takenAt: Date? = nil
    ) {
        self.selectedDate = selectedDate
        self.initialMemo = initialMemo
        self.initialStatus = initialStatus
        self.takenAt = takenAt
        self.selectedStatus = initialStatus
    }
    
    func transform(_ input: DashboardSheetViewModelInput) -> DashboardSheetViewModelOutput {
        
        let shouldShowSheet = input.viewDidAppear
            .asSignal(onErrorSignalWith: .empty())
        
        let initialButtonTag = Driver.just(initialStatus)
            .map { status -> StatusButtonTag in
                guard let status = status else { return .none }
                return PillStatusMapper.mapStatusToButtonTag(status)
            }
        
        let formattedTime = Driver.just(takenAt)
            .map { [weak self] date -> String in
                self?.formatTime(date) ?? "-"
            }
        
        let updatedTime = input.timeChanged
            .map { [weak self] date -> String in
                self?.formatTime(date) ?? "-"
            }
            .asDriver(onErrorJustReturn: "-")
        
        let finalFormattedTime = Driver.merge(formattedTime, updatedTime)
        
        let statusFromNotTaken = input.tapNotTaken
            .map { [weak self] _ -> PillStatus? in
                self?.selectedStatus = .todayNotTaken
                return .todayNotTaken
            }
        
        let statusFromTaken = input.tapTaken
            .map { [weak self] _ -> PillStatus? in
                self?.selectedStatus = .todayTaken
                return .todayTaken
            }
        
        let statusFromTakenDouble = input.tapTakenDouble
            .map { [weak self] _ -> PillStatus? in
                self?.selectedStatus = .takenDouble
                return .takenDouble
            }
        
        let isMemoPlaceholderHidden = input.memoText
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: false)
        
        let dismiss = input.requestDismiss
            .withLatestFrom(input.memoText) { [weak self] _, memo in
                (self?.selectedStatus, memo)
            }
            .asSignal(onErrorSignalWith: .empty())
        
        return DashboardSheetViewModelOutput(
            shouldShowSheet: shouldShowSheet,
            initialButtonTag: initialButtonTag,
            formattedTime: finalFormattedTime,
            isMemoPlaceholderHidden: isMemoPlaceholderHidden,
            dismiss: dismiss
        )
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        return date.formatted(style: .time24Hour)
    }
}
