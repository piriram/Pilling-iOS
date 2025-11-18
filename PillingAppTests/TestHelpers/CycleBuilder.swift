//
//  CycleBuilder.swift
//  PillingAppTests
//
//  Builder pattern for easy Cycle creation in tests (CORE!)
//

import Foundation
@testable import PillingApp

/// Builder for creating Cycle objects with fluent API
/// This is the CORE component for test data generation
final class CycleBuilder {

    // MARK: - Properties

    private var id: UUID = UUID()
    private var cycleNumber: Int = 1
    private var startDate: Date = TestConstants.defaultStartDate
    private var activeDays: Int = TestConstants.defaultActiveDays
    private var breakDays: Int = TestConstants.defaultBreakDays
    private var scheduledTime: String = TestConstants.defaultScheduledTime
    private var createdAt: Date = Date()
    private var currentDay: Int?
    private var recordStatuses: [Int: PillStatus] = [:]
    private var recordMemos: [Int: String] = [:]
    private var recordTakenAts: [Int: Date] = [:]

    // MARK: - Initializer

    init() {}

    // MARK: - Fluent API - Basic Configuration

    /// Set the cycle ID
    func withId(_ id: UUID) -> Self {
        self.id = id
        return self
    }

    /// Set the cycle number
    func withCycleNumber(_ number: Int) -> Self {
        self.cycleNumber = number
        return self
    }

    /// Set the start date
    func withStartDate(_ date: Date) -> Self {
        self.startDate = date
        return self
    }

    /// Set the number of active days
    func withActiveDays(_ days: Int) -> Self {
        self.activeDays = days
        return self
    }

    /// Set the number of break days
    func withBreakDays(_ days: Int) -> Self {
        self.breakDays = days
        return self
    }

    /// Set the scheduled time (HH:mm format)
    func withScheduledTime(_ time: String) -> Self {
        self.scheduledTime = time
        return self
    }

    /// Set the created at date
    func withCreatedAt(_ date: Date) -> Self {
        self.createdAt = date
        return self
    }

    // MARK: - Fluent API - Current Day

    /// Set the current day in the cycle (for relative date calculations)
    /// - Parameter day: Day number (1-28)
    func withCurrentDay(_ day: Int) -> Self {
        self.currentDay = day
        return self
    }

    /// Convenience method: same as withCurrentDay
    func day(_ day: Int) -> Self {
        withCurrentDay(day)
    }

    /// Convenience method: same as withScheduledTime
    func scheduledTime(_ time: String) -> Self {
        withScheduledTime(time)
    }

    // MARK: - Fluent API - Record Status

    /// Set status for a specific day
    /// - Parameters:
    ///   - day: Day number (1-28)
    ///   - status: PillStatus for that day
    func withRecordStatus(day: Int, status: PillStatus) -> Self {
        recordStatuses[day] = status
        return self
    }

    /// Set status for yesterday (relative to currentDay)
    func yesterdayStatus(_ status: PillStatus) -> Self {
        guard let current = currentDay else {
            fatalError("Must set currentDay before using yesterdayStatus")
        }
        let yesterday = current - 1
        guard yesterday >= 1 else {
            fatalError("Yesterday would be day \(yesterday), which is invalid")
        }
        return withRecordStatus(day: yesterday, status: status)
    }

    /// Set status for today (relative to currentDay)
    func todayStatus(_ status: PillStatus) -> Self {
        guard let current = currentDay else {
            fatalError("Must set currentDay before using todayStatus")
        }
        return withRecordStatus(day: current, status: status)
    }

    /// Set takenAt date for a specific day
    /// - Parameters:
    ///   - day: Day number (1-28)
    ///   - takenAt: Date when pill was taken
    func withTakenAt(day: Int, takenAt: Date) -> Self {
        recordTakenAts[day] = takenAt
        return self
    }

    /// Set memo for a specific day
    /// - Parameters:
    ///   - day: Day number (1-28)
    ///   - memo: Memo string
    func withMemo(day: Int, memo: String) -> Self {
        recordMemos[day] = memo
        return self
    }

    // MARK: - Fluent API - Consecutive Missed

    /// Set consecutive missed days before currentDay
    /// - Parameter count: Number of consecutive missed days
    func withConsecutiveMissedDays(_ count: Int) -> Self {
        guard let current = currentDay else {
            fatalError("Must set currentDay before using withConsecutiveMissedDays")
        }

        for i in 1...count {
            let day = current - i
            guard day >= 1 else { break }
            recordStatuses[day] = .missed
        }

        return self
    }

    /// Set yesterday as missed and today as taken double
    func yesterdayMissedTodayDouble() -> Self {
        guard let current = currentDay else {
            fatalError("Must set currentDay before using yesterdayMissedTodayDouble")
        }
        let yesterday = current - 1
        guard yesterday >= 1 else {
            fatalError("Yesterday would be day \(yesterday), which is invalid")
        }
        recordStatuses[yesterday] = .missed
        recordStatuses[current] = .takenDouble
        return self
    }

    // MARK: - Build

    /// Build the Cycle object
    /// - Returns: Configured Cycle
    func build() -> Cycle {
        let totalDays = activeDays + breakDays
        var records: [DayRecord] = []

        for day in 1...totalDays {
            let record = createRecord(for: day)
            records.append(record)
        }

        return Cycle(
            id: id,
            cycleNumber: cycleNumber,
            startDate: startDate,
            activeDays: activeDays,
            breakDays: breakDays,
            scheduledTime: scheduledTime,
            records: records,
            createdAt: createdAt
        )
    }

    // MARK: - Private Methods

    private func createRecord(for day: Int) -> DayRecord {
        // Calculate scheduled date/time for this day
        let scheduledDateTime = calculateScheduledDateTime(for: day)

        // Determine status
        let status = determineStatus(for: day)

        // Get takenAt if specified or if status is taken
        let takenAt = recordTakenAts[day] ?? (status.isTaken ? scheduledDateTime : nil)

        // Get memo
        let memo = recordMemos[day] ?? ""

        return DayRecord(
            id: UUID(),
            cycleDay: day,
            status: status,
            scheduledDateTime: scheduledDateTime,
            takenAt: takenAt,
            memo: memo,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    private func calculateScheduledDateTime(for day: Int) -> Date {
        let dayOffset = day - 1
        let dayDate = DateTestHelper.addDays(to: startDate, days: dayOffset)
        return DateTestHelper.makeTime(scheduledTime, on: dayDate)
    }

    private func determineStatus(for day: Int) -> PillStatus {
        // If explicitly set, use it
        if let status = recordStatuses[day] {
            return status
        }

        // If this is a break day, set to rest
        if day > activeDays {
            return .rest
        }

        // Default to scheduled for active days
        return .scheduled
    }
}

// MARK: - Convenience Extensions

extension CycleBuilder {

    /// Create a standard 24-4 cycle
    static func standard() -> CycleBuilder {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
    }

    /// Create a cycle for rest period testing (at day 25)
    static func restPeriod() -> CycleBuilder {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(25)
    }

    /// Create a cycle with 2 consecutive missed days
    static func twoConsecutiveMissed() -> CycleBuilder {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(5)
            .withConsecutiveMissedDays(2)
    }

    /// Create a cycle with 3 consecutive missed days
    static func threeConsecutiveMissed() -> CycleBuilder {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(6)
            .withConsecutiveMissedDays(3)
    }
}
