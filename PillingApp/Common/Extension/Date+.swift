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

import Foundation

extension Date {
    /// 내부 포맷터 캐시 재사용 (기존 formatted(...) 캐시 스타일과 동일한 키 구성 권장)
    private static var parseFormatterCache: [String: DateFormatter] = [:]
    private static let parseCacheLock = NSLock()
    
    /// 문자열을 주어진 스타일로 파싱해 Date로 변환
    static func parse(_ string: String, style: DateFormatStyle, timeZone: TimeZone = .current) -> Date? {
        let cacheKey = "parse-\(style.formatString)-\(style.locale.identifier)-\(timeZone.identifier)"
        
        parseCacheLock.lock()
        defer { parseCacheLock.unlock() }
        
        let formatter: DateFormatter
        if let cached = parseFormatterCache[cacheKey] {
            formatter = cached
        } else {
            let f = DateFormatter()
            f.dateFormat = style.formatString
            f.locale = style.locale
            f.timeZone = timeZone
            parseFormatterCache[cacheKey] = f
            formatter = f
        }
        return formatter.date(from: string)
    }
    
    /// 날짜(Date)의 연-월-일과, 시각 문자열을 결합하여 새로운 Date 생성
    static func combine(
        _ date: Date,
        with timeString: String,
        using style: DateFormatStyle,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> Date? {
        // 1) 시각 문자열을 파싱
        guard let timeOnly = Date.parse(timeString, style: style, timeZone: timeZone) else {
            return nil
        }
        // 2) 날짜/시각 컴포넌트 추출
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        let time = calendar.dateComponents([.hour, .minute, .second], from: timeOnly)
        
        var comps = DateComponents()
        comps.calendar = calendar
        comps.timeZone = timeZone
        comps.year = day.year
        comps.month = day.month
        comps.day = day.day
        comps.hour = time.hour
        comps.minute = time.minute
        comps.second = time.second ?? 0
        
        return calendar.date(from: comps)
    }
}
