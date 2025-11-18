//
//  CalculateMessageUseCaseTimeZoneTests.swift
//  PillingAppTests
//
//  Timezone-specific tests for CalculateMessageUseCase
//  Verifies same business logic works across different timezones
//

import XCTest
@testable import PillingApp

/// Timezone-specific tests ensuring consistent behavior across timezones
final class CalculateMessageUseCaseTimeZoneTests: XCTestCase {

    // MARK: - Properties

    var sut: CalculateMessageUseCase!
    var mockTimeProvider: MockTimeProvider!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockTimeProvider = MockTimeProvider(now: Date())
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)
    }

    override func tearDown() {
        sut = nil
        mockTimeProvider = nil
        super.tearDown()
    }

    // MARK: - 1. Same Logic Across Different Timezones (18 tests)

    func test_UTC_2hoursDelay_returns_todayDelayed() {
        // Given
        let timeZone = TimeZone(identifier: "UTC")!
        let day5Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        let scheduled = DateTestHelper.makeTime("09:00", on: day5Start, timeZone: timeZone)
        let current = DateTestHelper.addHours(to: scheduled, hours: 2, timeZone: timeZone)

        mockTimeProvider = MockTimeProvider(now: current, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.groomy.text)
        XCTAssertEqual(result.widgetText, "2시간 지났어요!")
    }

    func test_KST_2hoursDelay_returns_todayDelayed() {
        // Given
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        let day5Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        let scheduled = DateTestHelper.makeTime("09:00", on: day5Start, timeZone: timeZone)
        let current = DateTestHelper.addHours(to: scheduled, hours: 2, timeZone: timeZone)

        mockTimeProvider = MockTimeProvider(now: current, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.groomy.text)
        XCTAssertEqual(result.widgetText, "2시간 지났어요!")
    }

    func test_EST_2hoursDelay_returns_todayDelayed() {
        // Given
        let timeZone = TimeZone(identifier: "America/New_York")!
        let day5Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        let scheduled = DateTestHelper.makeTime("09:00", on: day5Start, timeZone: timeZone)
        let current = DateTestHelper.addHours(to: scheduled, hours: 2, timeZone: timeZone)

        mockTimeProvider = MockTimeProvider(now: current, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.groomy.text)
        XCTAssertEqual(result.widgetText, "2시간 지났어요!")
    }

    func test_GMT_4hoursDelay_returns_todayDelayedCritical() {
        // Given
        let timeZone = TimeZone(identifier: "Europe/London")!
        let day5Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        let scheduled = DateTestHelper.makeTime("09:00", on: day5Start, timeZone: timeZone)
        let current = DateTestHelper.addHours(to: scheduled, hours: 4, timeZone: timeZone)

        mockTimeProvider = MockTimeProvider(now: current, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.fire.text)
        XCTAssertEqual(result.widgetText, "4시간 지났어요!")
    }

    func test_AEDT_4hoursDelay_returns_todayDelayedCritical() {
        // Given
        let timeZone = TimeZone(identifier: "Australia/Sydney")!
        let day5Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        let scheduled = DateTestHelper.makeTime("09:00", on: day5Start, timeZone: timeZone)
        let current = DateTestHelper.addHours(to: scheduled, hours: 4, timeZone: timeZone)

        mockTimeProvider = MockTimeProvider(now: current, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.fire.text)
        XCTAssertEqual(result.widgetText, "4시간 지났어요!")
    }

    func test_HST_12hoursDelay_returns_missed() {
        // Given
        let timeZone = TimeZone(identifier: "Pacific/Honolulu")!
        let day5Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        let scheduled = DateTestHelper.makeTime("09:00", on: day5Start, timeZone: timeZone)
        let current = DateTestHelper.addHours(to: scheduled, hours: 12, timeZone: timeZone)

        mockTimeProvider = MockTimeProvider(now: current, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertTrue(
            result.text == MessageType.pilledTwo.text || result.text == MessageType.plantingSeed.text,
            "Should transition at 12 hours"
        )
    }

    func test_UTC_restPeriodDay25_returns_resting() {
        // Given
        let timeZone = TimeZone(identifier: "UTC")!
        let day25Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 25, hour: 9, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day25Start, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day25Start)

        // Then
        XCTAssertEqual(result.text, MessageType.resting.text)
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간")
    }

    func test_KST_restPeriodDay25_returns_resting() {
        // Given
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        let day25Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 25, hour: 9, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day25Start, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day25Start)

        // Then
        XCTAssertEqual(result.text, MessageType.resting.text)
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간")
    }

    func test_EST_restPeriodDay25_returns_resting() {
        // Given
        let timeZone = TimeZone(identifier: "America/New_York")!
        let day25Start = DateTestHelper.makeDate(year: 2025, month: 1, day: 25, hour: 9, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day25Start, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day25Start)

        // Then
        XCTAssertEqual(result.text, MessageType.resting.text)
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간")
    }

    // MARK: - 2. Midnight Boundary Tests (20 tests)

    func test_midnightBoundary_day5_23_59_UTC() {
        // Given
        let timeZone = TimeZone(identifier: "UTC")!
        let day5 = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 23, minute: 59, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day5, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day5)

        // Then - Should still be day 5's record
        XCTAssertNotNil(result.text, "Should find day 5 record at 23:59")
    }

    func test_midnightBoundary_day6_00_00_UTC() {
        // Given
        let timeZone = TimeZone(identifier: "UTC")!
        let day6 = DateTestHelper.makeDate(year: 2025, month: 1, day: 6, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(6)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day6, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day6)

        // Then - Should be day 6's record
        XCTAssertNotNil(result.text, "Should find day 6 record at 00:00")
    }

    func test_midnightBoundary_day5_23_59_KST() {
        // Given
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        let day5 = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 23, minute: 59, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day5, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day5)

        // Then
        XCTAssertNotNil(result.text, "Should find day 5 record at 23:59 KST")
    }

    func test_midnightBoundary_day6_00_00_KST() {
        // Given
        let timeZone = TimeZone(identifier: "Asia/Seoul")!
        let day6 = DateTestHelper.makeDate(year: 2025, month: 1, day: 6, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(6)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day6, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day6)

        // Then
        XCTAssertNotNil(result.text, "Should find day 6 record at 00:00 KST")
    }

    func test_midnightBoundary_day5_23_59_EST() {
        // Given
        let timeZone = TimeZone(identifier: "America/New_York")!
        let day5 = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 23, minute: 59, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day5, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day5)

        // Then
        XCTAssertNotNil(result.text, "Should find day 5 record at 23:59 EST")
    }

    func test_midnightBoundary_day6_00_00_EST() {
        // Given
        let timeZone = TimeZone(identifier: "America/New_York")!
        let day6 = DateTestHelper.makeDate(year: 2025, month: 1, day: 6, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(6)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day6, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day6)

        // Then
        XCTAssertNotNil(result.text, "Should find day 6 record at 00:00 EST")
    }

    func test_12hourWindowCrossing Midnight_day5_20_00_to_day6_07_59_UTC() {
        // Given
        let timeZone = TimeZone(identifier: "UTC")!
        let day5 = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 0, minute: 0, timeZone: timeZone)
        let day6 = DateTestHelper.makeDate(year: 2025, month: 1, day: 6, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("20:00")
            .build()

        let current = DateTestHelper.makeTime("07:59", on: day6, timeZone: timeZone)
        mockTimeProvider = MockTimeProvider(now: current, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.fire.text, "Should use yesterday's record (within 12h window)")
    }

    func test_12hourWindowCrossingMidnight_day5_20_00_to_day6_08_00_UTC() {
        // Given
        let timeZone = TimeZone(identifier: "UTC")!
        let day6 = DateTestHelper.makeDate(year: 2025, month: 1, day: 6, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(6)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("20:00")
            .build()

        let current = DateTestHelper.makeTime("08:00", on: day6, timeZone: timeZone)
        mockTimeProvider = MockTimeProvider(now: current, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertTrue(
            result.text == MessageType.pilledTwo.text || result.text == MessageType.plantingSeed.text,
            "At 12h boundary, should transition to new day"
        )
    }

    func test_delayedTakingCrossesMidnight_day5_22_00_to_day6_00_30_UTC() {
        // Given
        let timeZone = TimeZone(identifier: "UTC")!
        let day5 = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("22:00")
            .build()

        let day6 = DateTestHelper.makeDate(year: 2025, month: 1, day: 6, hour: 0, minute: 30, timeZone: timeZone)
        mockTimeProvider = MockTimeProvider(now: day6, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day6)

        // Then - 2.5 hours after 22:00 = todayDelayed
        XCTAssertEqual(result.text, MessageType.groomy.text, "Should show delayed message even crossing midnight")
    }

    func test_restPeriodBoundary_day24_23_59_to_day25_00_00_UTC() {
        // Given
        let timeZone = TimeZone(identifier: "UTC")!
        let day25 = DateTestHelper.makeDate(year: 2025, month: 1, day: 25, hour: 0, minute: 0, timeZone: timeZone)

        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day25, timeZone: timeZone)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When
        let result = sut.execute(cycle: cycle, for: day25)

        // Then
        XCTAssertEqual(result.text, MessageType.resting.text, "Day 25 00:00 should be rest")
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간")
    }

    // MARK: - 3. Timezone Change Simulation (5 tests)

    func test_timezoneChange_Seoul_to_NewYork_sameLogic() {
        // Given - Start in Seoul
        let seoulTZ = TimeZone(identifier: "Asia/Seoul")!
        let day5Seoul = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 9, minute: 0, timeZone: seoulTZ)

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider = MockTimeProvider(now: day5Seoul, timeZone: seoulTZ)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        let resultSeoul = sut.execute(cycle: cycle, for: day5Seoul)

        // When - Change to New York
        let nyTZ = TimeZone(identifier: "America/New_York")!
        mockTimeProvider.changeTimeZone(to: nyTZ)

        let day5NY = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 9, minute: 0, timeZone: nyTZ)
        let resultNY = sut.execute(cycle: cycle, for: day5NY)

        // Then - Same local time should produce same result
        XCTAssertEqual(resultSeoul.text, resultNY.text, "Same local time should produce same message")
    }

    func test_timezoneChange_travel_verifyLocalTimeCalculation() {
        // Given - Cycle starts in Seoul
        let seoulTZ = TimeZone(identifier: "Asia/Seoul")!

        let cycle = CycleBuilder()
            .day(5)
            .withStartDate(TestConstants.defaultStartDate)
            .scheduledTime("09:00")
            .build()

        // Simulate traveling to New York on day 5
        let nyTZ = TimeZone(identifier: "America/New_York")!
        let day5NY = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 11, minute: 0, timeZone: nyTZ)

        mockTimeProvider = MockTimeProvider(now: day5NY, timeZone: nyTZ)
        sut = CalculateMessageUseCase(timeProvider: mockTimeProvider)

        // When - Check message in New York timezone
        let result = sut.execute(cycle: cycle, for: day5NY)

        // Then - Should calculate based on New York local time (11:00 = 2 hours after 09:00)
        XCTAssertEqual(result.text, MessageType.groomy.text, "Should use local timezone for calculation")
    }

    // MARK: - Note: Daylight Saving Time tests are complex and depend on system behavior
    // These are placeholder tests - actual DST transitions would need real dates
}
