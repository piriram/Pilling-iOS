//
//  Date+.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/21/25.
//

import Foundation

enum DateFormatStyle {
    case koreanTimeWithPeriod
    case time24Hour
    case yearMonthDayPoint
    case noYear
    case monthDay
    case custom(String)
    
    private var configuration: (format: String, locale: Locale) {
        switch self {
        case .koreanTimeWithPeriod:
            return ("a h:mm", Locale(identifier: "ko_KR"))
        case .time24Hour:
            return ("HH:mm", .current)
        case .yearMonthDayPoint:
            return ("yyyy.MM.dd", .current)
        case .noYear:
            return ("MM.dd HH:mm", .current)
        case .monthDay:
            return ("M월 d일", Locale(identifier: "ko_KR"))
        case .custom(let format):
            return (format, .current)
        }
    }
    
    var formatString: String {
        configuration.format
    }
    
    var locale: Locale {
        configuration.locale
    }
}

extension Date {
    private static var formatterCache: [String: DateFormatter] = [:]
    private static let cacheLock = NSLock()
    
    func formatted(
        style: DateFormatStyle,
        timeZone: TimeZone = .current
    ) -> String {
        let cacheKey = "\(style.formatString)-\(style.locale.identifier)-\(timeZone.identifier)"
        
        Self.cacheLock.lock()
        defer { Self.cacheLock.unlock() }
        
        if let cachedFormatter = Self.formatterCache[cacheKey] {
            return cachedFormatter.string(from: self)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = style.formatString
        formatter.locale = style.locale
        formatter.timeZone = timeZone
        
        Self.formatterCache[cacheKey] = formatter
        
        return formatter.string(from: self)
    }
}

