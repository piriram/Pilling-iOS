import UIKit

@available(iOS 16.0, *)
final class CalendarSheetPresenter {
    static func present(from presenter: UIViewController,
                        selectedIndex: Int,
                        item: DayItem,
                        cycle: PillCycle,
                        update: @escaping (Int, PillStatus) -> Void) {
        // Compute day-of-cycle text like "4일차/28"
        let calendar = Calendar.current
        let daysSinceStart = max(0, calendar.dateComponents([.day], from: cycle.startDate, to: item.date).day ?? 0)
        let currentDay = min(daysSinceStart + 1, cycle.totalDays)
        let dayText = "\(currentDay)일차/\(cycle.totalDays)"

        let viewController = CalendarSheetViewController(selectedDate: item.date) { chosenStatus in
            update(selectedIndex, chosenStatus)
        }
        // Fallback: set title to show the day text
        viewController.title = dayText

        viewController.modalPresentationStyle = .pageSheet
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.preferredCornerRadius = 24
            sheet.prefersGrabberVisible = true
        }
        presenter.present(viewController, animated: true)
    }
}
