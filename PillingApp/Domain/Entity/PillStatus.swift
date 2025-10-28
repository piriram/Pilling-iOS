//
//  PillStatus.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/16/25.
//

import UIKit

enum PillStatus: Int,Sendable {
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
    case todayTakenTooEarly = 10
    case takenTooEarly = 11
    case todayDelayedCritical = 12
    
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
    
    var isToday: Bool {
        switch self {
        case .todayNotTaken, .todayTaken, .todayTakenDelayed, .todayDelayed, .todayTakenTooEarly, .todayDelayedCritical:
            return true
        default:
            return false
        }
    }
    
    var isTaken: Bool {
        switch self {
        case .taken, .takenDelayed, .takenDouble, .todayTaken, .todayTakenDelayed, .todayTakenTooEarly, .takenTooEarly:
            return true
        default:
            return false
        }
    }
}

extension PillStatus {
    
    /// 현재 상태를 오늘 날짜 기준으로 변환
    func asTodayVersion() -> PillStatus {
        switch self {
        case .taken:
            return .todayTaken
        case .takenDelayed:
            return .todayTakenDelayed
        case .takenTooEarly:
            return .todayTakenTooEarly
        case .scheduled:
            return .todayNotTaken
        case .missed:
            return .todayDelayed
        case .todayNotTaken, .todayTaken, .todayTakenDelayed, .todayDelayed, .takenDouble, .rest, .todayTakenTooEarly, .todayDelayedCritical:
            return self
        }
    }
    
    /// 현재 상태를 과거 날짜 기준으로 변환 (today prefix 제거)
    func asHistoricalVersion() -> PillStatus {
        switch self {
        case .todayTaken:
            return .taken
        case .todayTakenDelayed:
            return .takenDelayed
        case .todayTakenTooEarly:
            return .takenTooEarly
        case .todayNotTaken, .todayDelayed, .todayDelayedCritical:
            return .missed
        case .taken, .takenDelayed, .takenDouble, .missed, .scheduled, .rest, .takenTooEarly:
            return self
        }
    }
    
    /// 주어진 날짜가 오늘인지 확인하여 적절한 버전으로 변환
    func adjustedForDate(_ date: Date, calendar: Calendar = .current) -> PillStatus {
        let isDateToday = calendar.isDateInToday(date)
        return isDateToday ? asTodayVersion() : asHistoricalVersion()
    }
}
