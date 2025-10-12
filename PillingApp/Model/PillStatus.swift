//
//  PillStatus.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit
// MARK: - Domain/Entities/PillStatus.swift

enum PillStatus {
    case taken
    case takenDelayed
    case takenDouble
    case missed
    case todayNotTaken
    case todayTaken
    case todayTakenDelayed
    case todayDelayed
    case scheduled
    case rest
    
    var backgroundColor: UIColor {
        switch self {
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed:
            return AppColor.pillGreen800
        case .takenDouble:
            return AppColor.pillWhite
        case .missed:
            return AppColor.pillBrown
        case .scheduled, .todayNotTaken, .todayDelayed:
            return AppColor.notYetGray
        case .rest:
            return AppColor.pillWhite
        }
    }
    
    var isToday: Bool {
        switch self {
        case .todayNotTaken, .todayTaken, .todayTakenDelayed, .todayDelayed:
            return true
        default:
            return false
        }
    }
    
    var isTaken: Bool {
        switch self {
        case .taken, .takenDelayed, .takenDouble, .todayTaken, .todayTakenDelayed:
            return true
        default:
            return false
        }
    }
}
