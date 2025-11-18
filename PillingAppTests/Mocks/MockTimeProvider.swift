//
//  MockTimeProvider.swift
//  PillingAppTests
//
//  Created for comprehensive test infrastructure
//

import Foundation
@testable import PillingApp

/// Mock implementation of TimeProvider for complete time and timezone control in tests
final class MockTimeProvider: TimeProvider {

    // MARK: - Properties

    /// Current time returned by the mock
    var now: Date

    /// Calendar with synchronized timezone
    var calendar: Calendar {
        didSet {
            // Ensure calendar timezone is always synchronized with timeZone property
            calendar.timeZone = timeZone
        }
    }

    /// Current timezone
    var timeZone: TimeZone {
        didSet {
            // Ensure calendar timezone is always synchronized
            calendar.timeZone = timeZone
        }
    }

    // MARK: - Initializers

    /// Initialize with specific date and timezone
    /// - Parameters:
    ///   - now: The current date/time for testing
    ///   - timeZone: The timezone for testing (defaults to current)
    init(now: Date, timeZone: TimeZone = .current) {
        self.now = now
        self.timeZone = timeZone

        var cal = Calendar.current
        cal.timeZone = timeZone
        self.calendar = cal
    }

    /// Convenience initializer with date components
    /// - Parameters:
    ///   - year: Year component
    ///   - month: Month component
    ///   - day: Day component
    ///   - hour: Hour component (defaults to 0)
    ///   - minute: Minute component (defaults to 0)
    ///   - timeZone: Timezone (defaults to current)
    convenience init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        timeZone: TimeZone = .current
    ) {
        var cal = Calendar.current
        cal.timeZone = timeZone

        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )

        let date = cal.date(from: components) ?? Date()
        self.init(now: date, timeZone: timeZone)
    }

    // MARK: - TimeProvider Methods

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

    // MARK: - Test Helpers

    /// Change timezone (for timezone transition tests)
    /// - Parameter newTimeZone: The new timezone to use
    func changeTimeZone(to newTimeZone: TimeZone) {
        self.timeZone = newTimeZone
        var cal = Calendar.current
        cal.timeZone = newTimeZone
        self.calendar = cal
    }
}
