//
//  MockTimeProvider.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/16/25.
//

import UIKit
// MARK: - MockTimeProvider (테스트용)

#if DEBUG
final class MockTimeProvider: TimeProvider {
    var now: Date
    var timeZone: TimeZone
    
    var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal
    }
    
    init(
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) {
        self.now = now
        self.timeZone = timeZone
    }
    
    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    func isDateInToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: component, value: value, to: date)
    }
    
    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendar.dateComponents(components, from: date)
    }
}
#endif
