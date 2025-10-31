//
//  PillStatus+UIKit.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/16/25.
//

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
