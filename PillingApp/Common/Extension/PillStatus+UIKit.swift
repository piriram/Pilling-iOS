import UIKit

// MARK: - PillStatus + UIKit (본앱 전용)

extension PillStatus {

    var backgroundColor: UIColor {
        switch self {
        case .taken, .takenDelayed, .takenTooEarly:
            return AppColor.pillGreen800
        case .takenDouble:
            return AppColor.pillWhite
        case .missed, .recentlyMissed:
            return AppColor.pillBrown
        case .scheduled, .notTaken:
            return AppColor.notYetGray
        case .rest:
            return AppColor.pillWhite
        }
    }

    var backgroundImageName: String {
        switch self {
        case .taken, .takenDelayed, .takenTooEarly, .takenDouble:
            return "background_taken"
        case .missed, .recentlyMissed:
            return "background_taken"
        case .scheduled, .notTaken, .rest:
            return "background_rest"
        }
    }
}
