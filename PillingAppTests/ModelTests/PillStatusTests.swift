//
//  PillStatusTests.swift
//  PillingAppTests
//
//  Tests for PillStatus enum methods
//

import XCTest
@testable import PillingApp

/// Tests for PillStatus adjustment methods
final class PillStatusTests: XCTestCase {

    // MARK: - adjustedForDate Tests (30 tests)

    func test_adjustedForDate_today_taken_returns_todayTaken() {
        // Given
        let status = PillStatus.taken
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .todayTaken,
            "taken status on today should become todayTaken")
    }

    func test_adjustedForDate_today_takenDelayed_returns_todayTakenDelayed() {
        // Given
        let status = PillStatus.takenDelayed
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .todayTakenDelayed,
            "takenDelayed status on today should become todayTakenDelayed")
    }

    func test_adjustedForDate_today_takenTooEarly_returns_todayTakenTooEarly() {
        // Given
        let status = PillStatus.takenTooEarly
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .todayTakenTooEarly,
            "takenTooEarly status on today should become todayTakenTooEarly")
    }

    func test_adjustedForDate_today_scheduled_returns_todayNotTaken() {
        // Given
        let status = PillStatus.scheduled
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .todayNotTaken,
            "scheduled status on today should become todayNotTaken")
    }

    func test_adjustedForDate_today_missed_returns_todayDelayed() {
        // Given
        let status = PillStatus.missed
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .todayDelayed,
            "missed status on today should become todayDelayed")
    }

    func test_adjustedForDate_today_todayNotTaken_remainsSame() {
        // Given
        let status = PillStatus.todayNotTaken
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .todayNotTaken,
            "todayNotTaken should remain todayNotTaken")
    }

    func test_adjustedForDate_today_todayTaken_remainsSame() {
        // Given
        let status = PillStatus.todayTaken
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .todayTaken,
            "todayTaken should remain todayTaken")
    }

    func test_adjustedForDate_today_takenDouble_remainsSame() {
        // Given
        let status = PillStatus.takenDouble
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .takenDouble,
            "takenDouble should remain takenDouble")
    }

    func test_adjustedForDate_today_rest_remainsSame() {
        // Given
        let status = PillStatus.rest
        let today = Date()

        // When
        let result = status.adjustedForDate(today)

        // Then
        XCTAssertEqual(result, .rest,
            "rest should always remain rest")
    }

    func test_adjustedForDate_past_todayTaken_returns_taken() {
        // Given
        let status = PillStatus.todayTaken
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .taken,
            "todayTaken in the past should become taken")
    }

    func test_adjustedForDate_past_todayTakenDelayed_returns_takenDelayed() {
        // Given
        let status = PillStatus.todayTakenDelayed
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .takenDelayed,
            "todayTakenDelayed in the past should become takenDelayed")
    }

    func test_adjustedForDate_past_todayTakenTooEarly_returns_takenTooEarly() {
        // Given
        let status = PillStatus.todayTakenTooEarly
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .takenTooEarly,
            "todayTakenTooEarly in the past should become takenTooEarly")
    }

    func test_adjustedForDate_past_todayNotTaken_returns_missed() {
        // Given
        let status = PillStatus.todayNotTaken
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .missed,
            "todayNotTaken in the past should become missed")
    }

    func test_adjustedForDate_past_todayDelayed_returns_missed() {
        // Given
        let status = PillStatus.todayDelayed
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .missed,
            "todayDelayed in the past should become missed")
    }

    func test_adjustedForDate_past_todayDelayedCritical_returns_missed() {
        // Given
        let status = PillStatus.todayDelayedCritical
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .missed,
            "todayDelayedCritical in the past should become missed")
    }

    func test_adjustedForDate_past_taken_remainsSame() {
        // Given
        let status = PillStatus.taken
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .taken,
            "taken in the past should remain taken")
    }

    func test_adjustedForDate_past_missed_remainsSame() {
        // Given
        let status = PillStatus.missed
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .missed,
            "missed in the past should remain missed")
    }

    func test_adjustedForDate_past_rest_remainsSame() {
        // Given
        let status = PillStatus.rest
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .rest,
            "rest should always remain rest")
    }

    func test_adjustedForDate_past_scheduled_remainsSame() {
        // Given
        let status = PillStatus.scheduled
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .scheduled,
            "scheduled in the past should remain scheduled")
    }

    func test_adjustedForDate_past_takenDouble_remainsSame() {
        // Given
        let status = PillStatus.takenDouble
        let yesterday = DateTestHelper.addDays(to: Date(), days: -1)

        // When
        let result = status.adjustedForDate(yesterday)

        // Then
        XCTAssertEqual(result, .takenDouble,
            "takenDouble should remain takenDouble")
    }

    // MARK: - isToday Property Tests

    func test_isToday_todayNotTaken_returnsTrue() {
        XCTAssertTrue(PillStatus.todayNotTaken.isToday)
    }

    func test_isToday_todayTaken_returnsTrue() {
        XCTAssertTrue(PillStatus.todayTaken.isToday)
    }

    func test_isToday_todayTakenDelayed_returnsTrue() {
        XCTAssertTrue(PillStatus.todayTakenDelayed.isToday)
    }

    func test_isToday_todayDelayed_returnsTrue() {
        XCTAssertTrue(PillStatus.todayDelayed.isToday)
    }

    func test_isToday_todayTakenTooEarly_returnsTrue() {
        XCTAssertTrue(PillStatus.todayTakenTooEarly.isToday)
    }

    func test_isToday_todayDelayedCritical_returnsTrue() {
        XCTAssertTrue(PillStatus.todayDelayedCritical.isToday)
    }

    func test_isToday_taken_returnsFalse() {
        XCTAssertFalse(PillStatus.taken.isToday)
    }

    func test_isToday_missed_returnsFalse() {
        XCTAssertFalse(PillStatus.missed.isToday)
    }

    func test_isToday_rest_returnsFalse() {
        XCTAssertFalse(PillStatus.rest.isToday)
    }

    func test_isToday_takenDouble_returnsFalse() {
        XCTAssertFalse(PillStatus.takenDouble.isToday)
    }
}
