//
//  TimeScenario.swift
//  PillingAppTests
//
//  Helper for creating time scenarios in tests
//

import Foundation

/// Helper struct for creating scheduled time vs current time scenarios
struct TimeScenario {

    // MARK: - Scenario Creation

    /// Create a time scenario with scheduled and current times
    /// - Parameters:
    ///   - scheduledTime: Scheduled time in "HH:mm" format (e.g., "09:00")
    ///   - currentTime: Current time in "HH:mm" format (e.g., "11:00")
    ///   - date: Base date (defaults to 2025-01-01)
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: Tuple with scheduled and current dates
    static func make(
        scheduledTime: String,
        currentTime: String,
        date: Date = TestConstants.defaultStartDate,
        timeZone: TimeZone = .current
    ) -> (scheduled: Date, current: Date) {
        let scheduled = DateTestHelper.makeTime(scheduledTime, on: date, timeZone: timeZone)
        let current = DateTestHelper.makeTime(currentTime, on: date, timeZone: timeZone)

        return (scheduled: scheduled, current: current)
    }

    /// Create a time scenario with hour offset from scheduled time
    /// - Parameters:
    ///   - scheduledTime: Scheduled time in "HH:mm" format
    ///   - hourOffset: Hours to add to scheduled time (can be negative)
    ///   - date: Base date (defaults to 2025-01-01)
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: Tuple with scheduled and current dates
    static func makeWithOffset(
        scheduledTime: String,
        hourOffset: Double,
        date: Date = TestConstants.defaultStartDate,
        timeZone: TimeZone = .current
    ) -> (scheduled: Date, current: Date) {
        let scheduled = DateTestHelper.makeTime(scheduledTime, on: date, timeZone: timeZone)
        let current = scheduled.addingTimeInterval(hourOffset * 3600)

        return (scheduled: scheduled, current: current)
    }

    /// Create a time scenario with minute offset from scheduled time
    /// - Parameters:
    ///   - scheduledTime: Scheduled time in "HH:mm" format
    ///   - minuteOffset: Minutes to add to scheduled time (can be negative)
    ///   - date: Base date (defaults to 2025-01-01)
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: Tuple with scheduled and current dates
    static func makeWithMinuteOffset(
        scheduledTime: String,
        minuteOffset: Int,
        date: Date = TestConstants.defaultStartDate,
        timeZone: TimeZone = .current
    ) -> (scheduled: Date, current: Date) {
        let scheduled = DateTestHelper.makeTime(scheduledTime, on: date, timeZone: timeZone)
        let current = scheduled.addingTimeInterval(Double(minuteOffset) * 60)

        return (scheduled: scheduled, current: current)
    }

    /// Create a midnight crossing scenario
    /// - Parameters:
    ///   - scheduledTime: Scheduled time on first day (e.g., "23:00")
    ///   - currentTime: Current time on next day (e.g., "01:00")
    ///   - firstDate: Base date for scheduled time
    ///   - timeZone: Timezone (defaults to current)
    /// - Returns: Tuple with scheduled and current dates
    static func makeMidnightCrossing(
        scheduledTime: String,
        currentTime: String,
        firstDate: Date = TestConstants.defaultStartDate,
        timeZone: TimeZone = .current
    ) -> (scheduled: Date, current: Date) {
        let scheduled = DateTestHelper.makeTime(scheduledTime, on: firstDate, timeZone: timeZone)
        let nextDay = DateTestHelper.addDays(to: firstDate, days: 1, timeZone: timeZone)
        let current = DateTestHelper.makeTime(currentTime, on: nextDay, timeZone: timeZone)

        return (scheduled: scheduled, current: current)
    }
}
