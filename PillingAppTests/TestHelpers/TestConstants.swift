//
//  TestConstants.swift
//  PillingAppTests
//
//  Common constants used across tests
//

import Foundation

/// Constants used in tests to avoid magic numbers
struct TestConstants {

    // MARK: - Time Intervals

    static let twoHours: TimeInterval = 2 * 60 * 60
    static let fourHours: TimeInterval = 4 * 60 * 60
    static let twelveHours: TimeInterval = 12 * 60 * 60
    static let oneDay: TimeInterval = 24 * 60 * 60

    // MARK: - Cycle Configuration

    static let defaultActiveDays = 24
    static let defaultBreakDays = 4
    static let defaultTotalDays = 28
    static let defaultScheduledTime = "09:00"

    // MARK: - Default Start Date

    /// Reference start date for tests (2025-01-01 00:00:00 UTC)
    static let defaultStartDate = DateTestHelper.makeDate(
        year: 2025,
        month: 1,
        day: 1,
        hour: 0,
        minute: 0,
        timeZone: TimeZone(identifier: "UTC")!
    )
}
