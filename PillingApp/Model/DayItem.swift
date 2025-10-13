//
//  DayItem.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import UIKit

// MARK: - Domain/Entities/DayItem.swift

struct DayItem {
    let cycleDay: Int
    let date: Date
    let status: PillStatus
}

enum PillStatus: Int {
    case taken = 0
    case takenDelayed = 1
    case takenDouble = 2
    case missed = 3
    case todayNotTaken = 4
    case todayTaken = 5
    case todayTakenDelayed = 6
    case todayDelayed = 7
    case scheduled = 8
    case rest = 9
    
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
