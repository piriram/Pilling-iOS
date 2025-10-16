//
//  PillStatus.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/16/25.
//

import UIKit

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
extension PillStatus {
    
    /// 현재 상태를 오늘 날짜 기준으로 변환
    func asTodayVersion() -> PillStatus {
        switch self {
        case .taken:
            return .todayTaken
        case .takenDelayed:
            return .todayTakenDelayed
        case .scheduled:
            return .todayNotTaken
        case .missed:
            return .todayDelayed
        // 이미 today 버전이거나 변환 불필요한 경우
        case .todayNotTaken, .todayTaken, .todayTakenDelayed, .todayDelayed, .takenDouble, .rest:
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
        case .todayNotTaken, .todayDelayed:
            return .scheduled
        // 이미 historical 버전이거나 변환 불필요한 경우
        case .taken, .takenDelayed, .takenDouble, .missed, .scheduled, .rest:
            return self
        }
    }
    
    /// 주어진 날짜가 오늘인지 확인하여 적절한 버전으로 변환
    func adjustedForDate(_ date: Date, calendar: Calendar = .current) -> PillStatus {
        let isDateToday = calendar.isDateInToday(date)
        return isDateToday ? asTodayVersion() : asHistoricalVersion()
    }
}
