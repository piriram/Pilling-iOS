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
        cycle: PillCycle,
        update: @escaping (Int, PillStatus, String) -> Void
    ) {
        let calendar = Calendar.current
        let daysSinceStart = max(0, calendar.dateComponents([.day], from: cycle.startDate, to: item.date).day ?? 0)
        let currentDay = min(daysSinceStart + 1, cycle.totalDays)
        let dayText = "\(currentDay)일차/\(cycle.totalDays)"
        
        let viewController = CalendarSheetViewController(selectedDate: item.date) { chosenStatus, memo in
            update(selectedIndex, chosenStatus, memo)
        }
        
        viewController.titleText = dayText
        viewController.title = dayText
        viewController.setInitialSelection(for: item.status)
        
        presenter.present(viewController, animated: false)
    }
}
