import UIKit

// MARK: - PillStatus + UIKit (본앱 전용)

extension PillStatus {
    
    var backgroundColor: UIColor {
        switch self {
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed, .todayTakenTooEarly, .takenTooEarly:
            return AppColor.pillGreen800
        case .takenDouble:
            return AppColor.pillWhite
        case .missed:
            return AppColor.pillBrown
        case .scheduled, .todayNotTaken, .todayDelayed, .todayDelayedCritical:
            return AppColor.notYetGray
        case .rest:
            return AppColor.pillWhite
        }
    }
}
