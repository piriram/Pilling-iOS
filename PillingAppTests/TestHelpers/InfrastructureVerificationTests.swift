//
//  InfrastructureVerificationTests.swift
//  PillingAppTests
//
//  Verify test infrastructure works correctly
//

import XCTest
@testable import PillingApp

/// Verification tests for test infrastructure
final class InfrastructureVerificationTests: XCTestCase {

    // MARK: - CycleBuilder Tests

    func test_CycleBuilder_defaultCreation() {
        // Given & When
        let cycle = CycleBuilder().build()

        // Then
        XCTAssertEqual(cycle.activeDays, 24, "Should have default 24 active days")
        XCTAssertEqual(cycle.breakDays, 4, "Should have default 4 break days")
        XCTAssertEqual(cycle.records.count, 28, "Should have 28 total records")
        XCTAssertEqual(cycle.scheduledTime, "09:00", "Should have default scheduled time")
    }

    func test_CycleBuilder_specificDayStatusSetting() {
        // Given & When
        let cycle = CycleBuilder()
            .day(5)
            .withRecordStatus(day: 5, status: .todayTaken)
            .build()

        // Then
        let day5Record = cycle.records.first { $0.cycleDay == 5 }
        XCTAssertNotNil(day5Record, "Day 5 record should exist")
        XCTAssertEqual(day5Record?.status, .todayTaken, "Day 5 should have todayTaken status")
    }

    func test_CycleBuilder_restPeriodDays() {
        // Given & When
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .build()

        // Then - Active days
        let day1Record = cycle.records.first { $0.cycleDay == 1 }
        XCTAssertEqual(day1Record?.status, .scheduled, "Day 1 should be scheduled (active day)")

        let day24Record = cycle.records.first { $0.cycleDay == 24 }
        XCTAssertEqual(day24Record?.status, .scheduled, "Day 24 should be scheduled (last active day)")

        // Then - Rest days
        let day25Record = cycle.records.first { $0.cycleDay == 25 }
        XCTAssertEqual(day25Record?.status, .rest, "Day 25 should be rest (first break day)")

        let day28Record = cycle.records.first { $0.cycleDay == 28 }
        XCTAssertEqual(day28Record?.status, .rest, "Day 28 should be rest (last break day)")
    }

    func test_CycleBuilder_consecutiveMissedDays() {
        // Given & When
        let cycle = CycleBuilder()
            .day(5)
            .withConsecutiveMissedDays(2)
            .build()

        // Then
        let day3Record = cycle.records.first { $0.cycleDay == 3 }
        XCTAssertEqual(day3Record?.status, .missed, "Day 3 should be missed")

        let day4Record = cycle.records.first { $0.cycleDay == 4 }
        XCTAssertEqual(day4Record?.status, .missed, "Day 4 should be missed")

        let day5Record = cycle.records.first { $0.cycleDay == 5 }
        XCTAssertNotEqual(day5Record?.status, .missed, "Day 5 should not be missed (current day)")
    }

    // MARK: - MockTimeProvider Tests

    func test_MockTimeProvider_initialization() {
        // Given
        let testDate = DateTestHelper.makeDate(year: 2025, month: 1, day: 15, hour: 10, minute: 30)

        // When
        let mockTime = MockTimeProvider(now: testDate)

        // Then
        XCTAssertEqual(mockTime.now, testDate, "Should return the configured date")
    }

    func test_MockTimeProvider_timezoneChange() {
        // Given
        let testDate = DateTestHelper.makeDate(year: 2025, month: 1, day: 15, hour: 10, minute: 30)
        let mockTime = MockTimeProvider(now: testDate, timeZone: TimeZone(identifier: "UTC")!)

        // When
        mockTime.changeTimeZone(to: TimeZone(identifier: "Asia/Seoul")!)

        // Then
        XCTAssertEqual(mockTime.timeZone.identifier, "Asia/Seoul", "Timezone should be changed")
        XCTAssertEqual(mockTime.calendar.timeZone.identifier, "Asia/Seoul", "Calendar timezone should be synchronized")
    }

    // MARK: - DateTestHelper Tests

    func test_DateTestHelper_makeDate() {
        // Given & When
        let date = DateTestHelper.makeDate(year: 2025, month: 1, day: 15, hour: 9, minute: 30)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        // Then
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 9)
        XCTAssertEqual(components.minute, 30)
    }

    func test_DateTestHelper_addHours() {
        // Given
        let baseDate = DateTestHelper.makeDate(year: 2025, month: 1, day: 15, hour: 9, minute: 0)

        // When
        let newDate = DateTestHelper.addHours(to: baseDate, hours: 2)

        // Then
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: newDate)
        XCTAssertEqual(components.hour, 11, "Should add 2 hours")
    }

    func test_DateTestHelper_midnight() {
        // Given
        let date = DateTestHelper.makeDate(year: 2025, month: 1, day: 15, hour: 14, minute: 30)

        // When
        let midnight = DateTestHelper.midnight(of: date)

        // Then
        XCTAssertTrue(DateTestHelper.isAtMidnight(midnight), "Should be at midnight")
    }

    // MARK: - TimeScenario Tests

    func test_TimeScenario_make() {
        // Given & When
        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "11:00")

        // Then
        let calendar = Calendar.current
        let scheduledComponents = calendar.dateComponents([.hour, .minute], from: scenario.scheduled)
        let currentComponents = calendar.dateComponents([.hour, .minute], from: scenario.current)

        XCTAssertEqual(scheduledComponents.hour, 9)
        XCTAssertEqual(scheduledComponents.minute, 0)
        XCTAssertEqual(currentComponents.hour, 11)
        XCTAssertEqual(currentComponents.minute, 0)
    }

    func test_TimeScenario_makeWithOffset() {
        // Given & When
        let scenario = TimeScenario.makeWithOffset(scheduledTime: "09:00", hourOffset: 2.5)

        // Then
        let timeDifference = scenario.current.timeIntervalSince(scenario.scheduled)
        XCTAssertEqual(timeDifference, 2.5 * 3600, accuracy: 1.0, "Should be 2.5 hours apart")
    }

    // MARK: - CycleFixtures Tests

    func test_CycleFixtures_standard_24_4() {
        // Given & When
        let cycle = CycleFixtures.standard_24_4

        // Then
        XCTAssertEqual(cycle.activeDays, 24)
        XCTAssertEqual(cycle.breakDays, 4)
        XCTAssertEqual(cycle.records.count, 28)
    }

    func test_CycleFixtures_restPeriodDay25() {
        // Given & When
        let cycle = CycleFixtures.restPeriodDay25
        let day25Record = cycle.records.first { $0.cycleDay == 25 }

        // Then
        XCTAssertNotNil(day25Record)
        XCTAssertEqual(day25Record?.status, .rest, "Day 25 should be a rest day")
    }

    func test_CycleFixtures_consecutiveMissed2Days() {
        // Given & When
        let cycle = CycleFixtures.consecutiveMissed2Days

        // Then
        let day3Record = cycle.records.first { $0.cycleDay == 3 }
        let day4Record = cycle.records.first { $0.cycleDay == 4 }

        XCTAssertEqual(day3Record?.status, .missed, "Day 3 should be missed")
        XCTAssertEqual(day4Record?.status, .missed, "Day 4 should be missed")
    }
}
