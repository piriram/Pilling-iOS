//
//  CalendarSheetPresenter.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit

final class CalendarSheetPresenter {
    static func present(
        from presenter: UIViewController,
        selectedIndex: Int,
        item: DayItem,
        cycle: Cycle,
        update: @escaping (Int, PillStatus, String, Date?) -> Void
    ) {
        let calendar = Calendar.current
        let daysSinceStart = max(0, calendar.dateComponents([.day], from: cycle.startDate, to: item.date).day ?? 0)
        let currentDay = min(daysSinceStart + 1, cycle.totalDays)
        let dayText = "\(currentDay)일차/\(cycle.totalDays)"
        
        // 기존 메모와 복용 시간 가져오기
        let existingMemo = cycle.records[safe: selectedIndex]?.memo ?? ""
        var currentTakenAt = cycle.records[safe: selectedIndex]?.takenAt
        
        let viewController = DashboardSheetViewController(
            selectedDate: item.date,
            initialMemo: existingMemo,
            takenAt: currentTakenAt,
            initialStatus: item.status,
            onDataChanged: { chosenStatus, memo in
                if let status = chosenStatus {
                    update(selectedIndex, status, memo, currentTakenAt)
                } else {
                    // 메모만 변경된 경우, 기존 상태 유지
                    update(selectedIndex, item.status, memo, currentTakenAt)
                }
            },
            onTimeChanged: { newTime in
                currentTakenAt = newTime
                // 시간이 변경되면 즉시 업데이트
                update(selectedIndex, item.status, existingMemo, newTime)
            }
        )
        
        viewController.titleText = dayText
        viewController.title = dayText
        viewController.setInitialSelection(for: item.status)
        
        presenter.present(viewController, animated: false)
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
