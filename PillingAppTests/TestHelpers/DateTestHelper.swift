//
//  DateTestHelper.swift
//  PillingAppTests
//
//  Date manipulation utilities for tests
//

import Foundation

/// Utility struct for creating and manipulating dates in tests
struct DateTestHelper {

    // MARK: - Date Creation

    /// Create a date with specific components
    /// - Parameters:
    ///   - year: Year component
    ///   - month: Month component
    ///   - day: Day component
    ///   - hour: Hour component (defaults to 0)
    ///   - minute: Minute component (defaults to 0)
    ///   - second: Second component (defaults to 0)
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: Date object or crashes if invalid
    static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        timeZone: TimeZone = .current
    ) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let components = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )

        guard let date = calendar.date(from: components) else {
            fatalError("Invalid date components: \(components)")
        }

        return date
    }

    // MARK: - Date Manipulation

    /// Add hours to a date
    /// - Parameters:
    ///   - date: Source date
    ///   - hours: Hours to add (can be negative)
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: New date with hours added
    static func addHours(to date: Date, hours: Int, timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        guard let newDate = calendar.date(byAdding: .hour, value: hours, to: date) else {
            fatalError("Failed to add \(hours) hours to \(date)")
        }

        return newDate
    }

    /// Add minutes to a date
    /// - Parameters:
    ///   - date: Source date
    ///   - minutes: Minutes to add (can be negative)
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: New date with minutes added
    static func addMinutes(to date: Date, minutes: Int, timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        guard let newDate = calendar.date(byAdding: .minute, value: minutes, to: date) else {
            fatalError("Failed to add \(minutes) minutes to \(date)")
        }

        return newDate
    }

    /// Add days to a date
    /// - Parameters:
    ///   - date: Source date
    ///   - days: Days to add (can be negative)
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: New date with days added
    static func addDays(to date: Date, days: Int, timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        guard let newDate = calendar.date(byAdding: .day, value: days, to: date) else {
            fatalError("Failed to add \(days) days to \(date)")
        }

        return newDate
    }

    // MARK: - Date Queries

    /// Get midnight (start of day) for a date
    /// - Parameters:
    ///   - date: Source date
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: Midnight of the given date
    static func midnight(of date: Date, timeZone: TimeZone = .current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.startOfDay(for: date)
    }

    /// Check if a date is at midnight
    /// - Parameters:
    ///   - date: Date to check
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: True if the date is exactly at midnight
    static func isAtMidnight(_ date: Date, timeZone: TimeZone = .current) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        return components.hour == 0 && components.minute == 0 && components.second == 0
    }

    /// Parse time string (HH:mm format) and create date on a specific day
    /// - Parameters:
    ///   - timeString: Time in "HH:mm" format (e.g., "09:30")
    ///   - baseDate: Base date to use (defaults to today)
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: Date with the specified time
    static func makeTime(
        _ timeString: String,
        on baseDate: Date = Date(),
        timeZone: TimeZone = .current
    ) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else {
            fatalError("Invalid time format: \(timeString). Expected format: HH:mm")
        }

        let hour = components[0]
        let minute = components[1]

        var dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0

        guard let date = calendar.date(from: dateComponents) else {
            fatalError("Failed to create date from time: \(timeString)")
        }

        return date
    }

    /// Get time interval in hours between two dates
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Number of hours between dates
    static func hoursBetween(from: Date, to: Date) -> Double {
        to.timeIntervalSince(from) / 3600
    }
}
