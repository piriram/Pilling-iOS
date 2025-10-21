//
//  Date+.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/21/25.
//

import Foundation

enum DateFormatStyle {
    case koreanTimeWithPeriod  // "오전 9:00"
    case time24Hour            // "09:00"
    case time12Hour            // "9:00 AM"
    case fullDate              // "2025년 10월 21일"
    case shortDate             // "10/21"
    case yearMonthDay          // "2025-10-21"
    case yearMonthDayPoint          // "2025.10.21"
    case noYear          // "2025.10.21"
    case monthDay              // "10월 21일"
    case custom(String)
    
    var formatString: String {
        switch self {
        case .koreanTimeWithPeriod:
            return "a h:mm"
        case .time24Hour:
            return "HH:mm"
        case .time12Hour:
            return "h:mm a"
        case .fullDate:
            return "yyyy년 M월 d일"
        case .shortDate:
            return "MM/dd"
        case .yearMonthDay:
            return "yyyy-MM-dd"
        case .yearMonthDayPoint:
            return "yyyy.MM.dd"
        case .noYear:
            return "MM.dd HH:mm"
        case .monthDay:
            return "M월 d일"
        case .custom(let format):
            return format
        }
    }
    
    var locale: Locale {
        switch self {
        case .koreanTimeWithPeriod, .fullDate, .monthDay:
            return Locale(identifier: "ko_KR")
        default:
            return Locale.current
        }
    }
}

extension Date {
    func formatted(
        style: DateFormatStyle,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = style.formatString
        formatter.locale = style.locale
        formatter.timeZone = timeZone
        return formatter.string(from: self)
    }
}
