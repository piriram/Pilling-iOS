//
//  CalculateMessageUseCaseTests.swift
//  PillingAppTests
//
//  Core business logic tests for CalculateMessageUseCase (PRIORITY 1)
//  Tests medical accuracy of time-based status transitions with widget integration
//

import XCTest
@testable import PillingApp

/// Comprehensive tests for CalculateMessageUseCase
/// Verifies time thresholds, rest periods, consecutive missed logic, and widget integration
final class CalculateMessageUseCaseTests: XCTestCase {

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

    // MARK: - 1. Time Threshold Tests (20 tests)

    func test_beforeScheduledTime_1hourBefore_returns_todayNotTaken() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "08:00")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Should show planting seed message 1 hour before scheduled time")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show short planting message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_exactScheduledTime_returns_todayNotTaken() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "09:00")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Should show planting seed message at exact scheduled time")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show short planting message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_1_5hoursAfter_returns_todayNotTaken() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "10:30")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Should show planting seed message 1.5 hours after (before 2-hour threshold)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show short planting message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_exactly2hours_boundary_returns_todayDelayed() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "11:00")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.groomy.text,
            "Should show groomy message at exactly 2 hours (boundary)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "2시간 지났어요!",
            "Widget should show 2-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_groomy",
            "Widget background should be groomy")
    }

    func test_2hours1minute_returns_todayDelayed() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "11:01")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.groomy.text,
            "Should show groomy message at 2 hours 1 minute")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "2시간 지났어요!",
            "Widget should show 2-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_groomy",
            "Widget background should be groomy")
    }

    func test_1hour59minutes_returns_todayNotTaken() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "10:59")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Should show planting seed message at 1:59 (just before 2-hour boundary)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show short planting message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_3hoursAfter_returns_todayDelayed() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "12:00")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.groomy.text,
            "Should show groomy message at 3 hours (between 2-4 hours)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "2시간 지났어요!",
            "Widget should show 2-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_groomy",
            "Widget background should be groomy")
    }

    func test_exactly4hours_boundary_returns_todayDelayedCritical() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "13:00")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "Should show fire message at exactly 4 hours (boundary)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_fire",
            "Widget background should be fire")
    }

    func test_4hours1minute_returns_todayDelayedCritical() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "13:01")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "Should show fire message at 4 hours 1 minute")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_fire",
            "Widget background should be fire")
    }

    func test_3hours59minutes_returns_todayDelayed() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "12:59")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.groomy.text,
            "Should show groomy message at 3:59 (just before 4-hour boundary)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "2시간 지났어요!",
            "Widget should show 2-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_groomy",
            "Widget background should be groomy")
    }

    func test_8hoursAfter_returns_todayDelayedCritical() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "17:00")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "Should show fire message at 8 hours (between 4-12 hours)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_fire",
            "Widget background should be fire")
    }

    func test_11hoursAfter_returns_todayDelayedCritical() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "20:00")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "Should show fire message at 11 hours")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_fire",
            "Widget background should be fire")
    }

    func test_exactly12hours_boundary_returns_missed() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "21:00")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.pilledTwo.text,
            "Should show pilledTwo message at exactly 12 hours (boundary)")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for pilledTwo (fallback to main text)")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_12hours1minute_returns_missed() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "21:01")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.pilledTwo.text,
            "Should show pilledTwo message at 12 hours 1 minute")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for pilledTwo (fallback to main text)")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_11hours59minutes_returns_todayDelayedCritical() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "20:59")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "Should show fire message at 11:59 (just before 12-hour boundary)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_fire",
            "Widget background should be fire")
    }

    func test_15hoursAfter_returns_missed() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let scheduled = DateTestHelper.makeTime("09:00", on: day5Start)
        let current = DateTestHelper.addHours(to: scheduled, hours: 15)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.pilledTwo.text,
            "Should show pilledTwo message at 15 hours (well past 12-hour threshold)")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for pilledTwo (fallback to main text)")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_30minutesBefore_returns_todayNotTaken() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "08:30")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Should show planting seed message 30 minutes before scheduled time")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show short planting message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_2_5hoursAfter_returns_todayDelayed() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "11:30")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.groomy.text,
            "Should show groomy message at 2.5 hours")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "2시간 지났어요!",
            "Widget should show 2-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_groomy",
            "Widget background should be groomy")
    }

    func test_6_5hoursAfter_returns_todayDelayedCritical() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "15:30")
        mockTimeProvider.now = scenario.current

        // When
        let result = sut.execute(cycle: cycle, for: scenario.current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "Should show fire message at 6.5 hours")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_fire",
            "Widget background should be fire")
    }

    // MARK: - 2. Rest Period Tests (15 tests) - BUG FIX TARGET

    func test_restPeriod_day1_notRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day1Start = TestConstants.defaultStartDate
        let current = DateTestHelper.makeTime("09:00", on: day1Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertNotEqual(result.text, MessageType.resting.text,
            "Day 1 should not be rest period")

        // Then - Widget
        XCTAssertNotEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 1 widget should not show rest message")
    }

    func test_restPeriod_day12_notRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day12Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 11)
        let current = DateTestHelper.makeTime("09:00", on: day12Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertNotEqual(result.text, MessageType.resting.text,
            "Day 12 should not be rest period")

        // Then - Widget
        XCTAssertNotEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 12 widget should not show rest message")
    }

    func test_restPeriod_day23_notRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day23Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 22)
        let current = DateTestHelper.makeTime("09:00", on: day23Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertNotEqual(result.text, MessageType.resting.text,
            "Day 23 should not be rest period")

        // Then - Widget
        XCTAssertNotEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 23 widget should not show rest message")
    }

    func test_restPeriod_day24_lastActiveDay_notRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day24Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 23)
        let current = DateTestHelper.makeTime("09:00", on: day24Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertNotEqual(result.text, MessageType.resting.text,
            "Day 24 (last active day) should NOT be rest period - CRITICAL BOUNDARY")

        // Then - Widget
        XCTAssertNotEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 24 widget should not show rest message")
    }

    func test_restPeriod_day25_firstRestDay_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day25Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 24)
        let current = DateTestHelper.makeTime("09:00", on: day25Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 25 (first rest day) should be rest period - CRITICAL BOUNDARY")
        XCTAssertEqual(result.iconImageName, "rest",
            "Icon should be rest")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 25 widget should show rest message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal for rest")
    }

    func test_restPeriod_day26_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day26Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 25)
        let current = DateTestHelper.makeTime("09:00", on: day26Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 26 should be rest period")
        XCTAssertEqual(result.iconImageName, "rest",
            "Icon should be rest")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 26 widget should show rest message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal for rest")
    }

    func test_restPeriod_day27_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day27Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 26)
        let current = DateTestHelper.makeTime("09:00", on: day27Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 27 should be rest period")
        XCTAssertEqual(result.iconImageName, "rest",
            "Icon should be rest")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 27 widget should show rest message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal for rest")
    }

    func test_restPeriod_day28_lastRestDay_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day28Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 27)
        let current = DateTestHelper.makeTime("09:00", on: day28Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 28 (last rest day) should be rest period")
        XCTAssertEqual(result.iconImageName, "rest",
            "Icon should be rest")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 28 widget should show rest message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal for rest")
    }

    func test_restPeriod_day24_23_59_notRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day24Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 23)
        let current = DateTestHelper.makeTime("23:59", on: day24Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertNotEqual(result.text, MessageType.resting.text,
            "Day 24 at 23:59 should NOT be rest (boundary test)")

        // Then - Widget
        XCTAssertNotEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 24 widget should not show rest message at 23:59")
    }

    func test_restPeriod_day25_00_00_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day25Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 24)
        let current = DateTestHelper.makeTime("00:00", on: day25Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 25 at 00:00 should be rest (boundary test)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 25 widget should show rest message at 00:00")
    }

    func test_restPeriod_differentScheduleTime_day25_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("21:00")
            .build()

        let day25Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 24)
        let current = DateTestHelper.makeTime("21:00", on: day25Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 25 should be rest regardless of scheduled time")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 25 widget should show rest message")
    }

    func test_restPeriod_earlyMorning_day25_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("06:00")
            .build()

        let day25Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 24)
        let current = DateTestHelper.makeTime("06:00", on: day25Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 25 should be rest at early morning time")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 25 widget should show rest message")
    }

    func test_restPeriod_lateNight_day27_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day27Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 26)
        let current = DateTestHelper.makeTime("23:30", on: day27Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 27 should be rest at late night")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 27 widget should show rest message")
    }

    func test_restPeriod_customCycle_21_7_day22_isRest() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(21)
            .withBreakDays(7)
            .scheduledTime("09:00")
            .build()

        let day22Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 21)
        let current = DateTestHelper.makeTime("09:00", on: day22Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 22 should be rest for 21-7 cycle")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Day 22 widget should show rest message for 21-7 cycle")
    }

    // MARK: - 3. Consecutive Missed Logic (15 tests)

    func test_consecutiveMissed_1day_notWaiting() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(1)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("09:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertNotEqual(result.text, MessageType.waiting.text,
            "1 day missed should not show waiting message")

        // Then - Widget
        XCTAssertNotEqual(result.widgetText, "잔디가 기다려요",
            "1 day missed widget should not show waiting")
    }

    func test_consecutiveMissed_2days_todayNotTaken_showsWaiting() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(2)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("09:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.waiting.text,
            "2 consecutive missed days should show waiting message")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디가 기다려요",
            "2 consecutive missed widget should show waiting")
        XCTAssertEqual(result.backgroundImageName, "widget_background_warning",
            "Widget background should be warning")
    }

    func test_consecutiveMissed_3days_todayNotTaken_showsWaiting() {
        // Given
        let cycle = CycleBuilder()
            .day(6)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(3)
            .build()

        let day6Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 5)
        let current = DateTestHelper.makeTime("09:00", on: day6Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.waiting.text,
            "3 consecutive missed days should show waiting message")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디가 기다려요",
            "3 consecutive missed widget should show waiting")
        XCTAssertEqual(result.backgroundImageName, "widget_background_warning",
            "Widget background should be warning")
    }

    func test_consecutiveMissed_2days_todayTaken_showsSuccess() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:15", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(2)
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.success.text,
            "2 consecutive missed + today taken should show success")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "Success type has no widget-specific text (uses main text)")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_consecutiveMissed_3days_todayTaken_showsSuccess() {
        // Given
        let day6Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 5)
        let takenTime = DateTestHelper.makeTime("09:20", on: day6Start)

        let cycle = CycleBuilder()
            .day(6)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(3)
            .todayStatus(.todayTaken)
            .withTakenAt(day: 6, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("11:00", on: day6Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.success.text,
            "3 consecutive missed + today taken should show success")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "Success type has no widget-specific text")
    }

    func test_consecutiveMissed_2days_todayTakenDelayed_showsSuccess() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("11:30", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(2)
            .todayStatus(.todayTakenDelayed)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("12:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.success.text,
            "2 consecutive missed + today taken delayed should show success")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "Success type has no widget-specific text")
    }

    func test_consecutiveMissed_2days_todayTakenTooEarly_showsSuccess() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("06:30", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(2)
            .todayStatus(.todayTakenTooEarly)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.success.text,
            "2 consecutive missed + today taken too early should show success")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "Success type has no widget-specific text")
    }

    func test_consecutiveMissed_restDaysExcluded() {
        // Given: Day 25, 26 are rest days (should not count as missed)
        // Day 27 is rest but let's say we're checking from day 28 (rest) to day 1 (next cycle)
        // This is a complex scenario - let's test simpler: days 22, 23 missed, day 25-27 rest, checking day 28
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .withRecordStatus(day: 22, status: .missed)
            .withRecordStatus(day: 23, status: .missed)
            .withRecordStatus(day: 24, status: .missed)
            // Day 25-28 are automatically rest
            .build()

        let day28Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 27)
        let current = DateTestHelper.makeTime("09:00", on: day28Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Rest days should not be counted in consecutive missed")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Should show rest message, not waiting")
    }

    func test_consecutiveMissed_2days_delayed4hours_stillShowsWaiting() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(2)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("13:00", on: day5Start) // +4 hours
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.waiting.text,
            "2 consecutive missed takes priority over delay status")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디가 기다려요",
            "Should show waiting, not delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_warning",
            "Widget background should be warning, not fire")
    }

    func test_consecutiveMissed_4days_todayNotTaken_showsWaiting() {
        // Given
        let cycle = CycleBuilder()
            .day(7)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(4)
            .build()

        let day7Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 6)
        let current = DateTestHelper.makeTime("09:00", on: day7Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.waiting.text,
            "4 consecutive missed days should show waiting message")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디가 기다려요",
            "4 consecutive missed widget should show waiting")
    }

    func test_consecutiveMissed_2days_then1taken_then1missed_resetsCount() {
        // Given: Days 3,4 missed, day 5 taken, day 6 missed (count should be 1, not 3)
        let day6Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 5)
        let day5TakenTime = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)

        let cycle = CycleBuilder()
            .day(7)
            .scheduledTime("09:00")
            .withRecordStatus(day: 3, status: .missed)
            .withRecordStatus(day: 4, status: .missed)
            .withRecordStatus(day: 5, status: .taken)
            .withTakenAt(day: 5, takenAt: DateTestHelper.makeTime("09:10", on: day5TakenTime))
            .withRecordStatus(day: 6, status: .missed)
            .build()

        let current = DateTestHelper.makeTime("09:00", on: DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 6))
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertNotEqual(result.text, MessageType.waiting.text,
            "Taking a pill should reset consecutive count (only 1 missed after taken)")

        // Then - Widget
        XCTAssertNotEqual(result.widgetText, "잔디가 기다려요",
            "Should not show waiting with reset count")
    }

    func test_consecutiveMissed_5days_todayTaken_showsSuccess() {
        // Given
        let day8Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 7)
        let takenTime = DateTestHelper.makeTime("09:10", on: day8Start)

        let cycle = CycleBuilder()
            .day(8)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(5)
            .todayStatus(.todayTaken)
            .withTakenAt(day: 8, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day8Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.success.text,
            "5 consecutive missed + today taken should show success")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "Success type has no widget-specific text")
    }

    func test_consecutiveMissed_2days_at2hourDelay_prioritizesWaiting() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(2)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("11:00", on: day5Start) // +2 hours
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.waiting.text,
            "Consecutive missed takes priority over 2-hour delay")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디가 기다려요",
            "Should show waiting, not groomy")
        XCTAssertEqual(result.backgroundImageName, "widget_background_warning",
            "Should use warning background, not groomy")
    }

    func test_consecutiveMissed_2days_at12hourBoundary_showsWaiting() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(2)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("21:00", on: day5Start) // +12 hours
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.waiting.text,
            "Consecutive missed takes priority even at 12-hour boundary")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디가 기다려요",
            "Should show waiting, not pilledTwo")
    }

    // MARK: - 4. Yesterday Missed + Today Status Combinations (25 tests)

    func test_yesterdayMissed_todayTakenDouble_showsTakingBefore() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.takenDouble)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBefore.text,
            "Yesterday missed + today taken double should show takingBefore")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBefore has no widget-specific text")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_yesterdayMissed_todayTaken1Pill_showsWarning() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBeforeTwo.text,
            "Yesterday missed + today taken 1 pill + consecutiveMissed=1 should show takingBeforeTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBeforeTwo has no widget-specific text")
    }

    func test_yesterdayMissed_todayNotTaken_within12hours_showsPilledTwo() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayNotTaken)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("08:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.pilledTwo.text,
            "Yesterday missed + today not taken should show pilledTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "pilledTwo has no widget-specific text")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_yesterdayMissed_consecutiveMissed1_todayTaken_showsTakingBeforeTwo() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBeforeTwo.text,
            "Yesterday missed + consecutiveMissed=1 + today taken should show takingBeforeTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBeforeTwo has no widget-specific text")
    }

    func test_yesterdayMissed_todayTakenTooEarly_showsWarning() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("06:00", on: day5Start) // 3 hours early

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.takenTooEarly)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBeforeTwo.text,
            "Yesterday missed + today taken too early (1 pill) should show takingBeforeTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBeforeTwo has no widget-specific text")
    }

    func test_yesterdayTaken_todayNotTaken_normalMessage() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4TakenTime = DateTestHelper.makeTime("09:10", on: day4Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.taken)
            .withTakenAt(day: 4, takenAt: day4TakenTime)
            .todayStatus(.todayNotTaken)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("09:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Yesterday taken + today not taken should show normal plantingSeed")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show normal planting message")
    }

    func test_yesterdayMissed_todayDelayed2hours_showsPilledTwo() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayNotTaken)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("11:00", on: day5Start) // +2 hours
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.pilledTwo.text,
            "Yesterday missed + today delayed should show pilledTwo (takes priority)")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "pilledTwo has no widget-specific text")
    }

    func test_yesterdayMissed_todayDelayed4hours_showsPilledTwo() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayNotTaken)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("13:00", on: day5Start) // +4 hours
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.pilledTwo.text,
            "Yesterday missed + today critical delay should show pilledTwo (takes priority)")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "pilledTwo has no widget-specific text")
    }

    func test_yesterdayMissed_todayTakenDelayed_showsTakingBeforeTwo() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("11:30", on: day5Start) // Taken at +2.5 hours

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayTakenDelayed)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("12:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBeforeTwo.text,
            "Yesterday missed + today taken delayed (1 pill) should show takingBeforeTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBeforeTwo has no widget-specific text")
    }

    func test_yesterdayTakenDelayed_todayNotTaken_normalMessage() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4TakenTime = DateTestHelper.makeTime("11:30", on: day4Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.takenDelayed)
            .withTakenAt(day: 4, takenAt: day4TakenTime)
            .todayStatus(.todayNotTaken)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("09:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Yesterday taken delayed + today not taken should show normal message")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show normal planting message")
    }

    func test_2daysAgoMissed_yesterdayTaken_todayNotTaken_normalMessage() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4TakenTime = DateTestHelper.makeTime("09:10", on: day4Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withRecordStatus(day: 3, status: .missed)
            .withRecordStatus(day: 4, status: .taken)
            .withTakenAt(day: 4, takenAt: day4TakenTime)
            .todayStatus(.todayNotTaken)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("09:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Missed 2 days ago but taken yesterday should not affect today")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show normal planting message")
    }

    func test_yesterdayMissed_todayTakenDouble_at2hourDelay() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("11:00", on: day5Start) // +2 hours

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.takenDouble)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("12:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBefore.text,
            "Yesterday missed + today taken double (even delayed) should show takingBefore")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBefore has no widget-specific text")
    }

    func test_yesterdayMissed_todayTakenDouble_early() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("08:00", on: day5Start) // -1 hour

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.takenDouble)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBefore.text,
            "Yesterday missed + today taken double (even early) should show takingBefore")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBefore has no widget-specific text")
    }

    func test_yesterdayRest_todayNotTaken_normalMessage() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day26Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 25)
        let current = DateTestHelper.makeTime("09:00", on: day26Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Yesterday rest + today rest should show resting")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Widget should show rest message")
    }

    func test_yesterdayMissed_todayNotTaken_beforeScheduledTime() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayNotTaken)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("08:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.pilledTwo.text,
            "Yesterday missed + today before scheduled time should show pilledTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "pilledTwo has no widget-specific text")
    }

    func test_yesterdayMissed_todayScheduled_shouldntHappen() {
        // Given: This is an edge case where today's record is still 'scheduled'
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.scheduled)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("09:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - We expect the system to handle this gracefully
        XCTAssertNotNil(result.text, "Should return some message")
    }

    func test_yesterdayMissed_todayTaken_atExactScheduledTime() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:00", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBeforeTwo.text,
            "Yesterday missed + today taken at exact time should show takingBeforeTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBeforeTwo has no widget-specific text")
    }

    func test_yesterdayMissed_todayTakenDouble_rightAfterMidnight() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("00:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.takenDouble)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBefore.text,
            "Yesterday missed + today taken double (even very early) should show takingBefore")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBefore has no widget-specific text")
    }

    func test_yesterdayMissed_todayNotTaken_lateNight() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayNotTaken)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("23:30", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.pilledTwo.text,
            "Yesterday missed + today not taken (late night) should show pilledTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "pilledTwo has no widget-specific text")
    }

    func test_yesterdayMissed_2daysAgoMissed_todayTaken_shows2ConsecutiveLogic() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withConsecutiveMissedDays(2) // Days 3 and 4 missed
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.success.text,
            "2 consecutive missed + today taken should prioritize success (not takingBeforeTwo)")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "success has no widget-specific text")
    }

    func test_yesterdayMissed_todayTaken_checkingHoursLater() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("20:00", on: day5Start) // 11 hours later
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBeforeTwo.text,
            "Yesterday missed + today taken should show takingBeforeTwo even when checked hours later")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBeforeTwo has no widget-specific text")
    }

    func test_yesterdayMissed_todayTakenDouble_checkingNextDay() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.takenDouble)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("23:59", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBefore.text,
            "Yesterday missed + today taken double should show takingBefore even near midnight")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBefore has no widget-specific text")
    }

    func test_yesterdayMissed_todayNotTaken_exactlyAt12hourWindow() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4Scheduled = DateTestHelper.makeTime("09:00", on: day4Start)

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("09:00", on: day5Start) // Exactly 24 hours later

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.todayNotTaken)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "At 24 hours (new day), should show today's plantingSeed message")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show planting message for new day")
    }

    func test_yesterdayMissed_todayTakenTooEarly_3hoursBefore() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("06:00", on: day5Start) // 3 hours before 09:00

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .todayStatus(.takenTooEarly)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takingBeforeTwo.text,
            "Yesterday missed + today taken too early should show takingBeforeTwo")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takingBeforeTwo has no widget-specific text")
    }

    // MARK: - 5. Taken Status After Taking (15 tests)

    func test_takenStatus_30minutesBefore_returns_todayTaken() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("08:30", on: day5Start) // 30 min before 09:00

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.todayAfter.text,
            "Taking 30 min before scheduled should show todayAfter (within 2 hours)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Widget should show completion message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    func test_takenStatus_1hourBefore_returns_todayTaken() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("08:00", on: day5Start) // 1 hour before

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.todayAfter.text,
            "Taking 1 hour before scheduled should show todayAfter")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Widget should show completion message")
    }

    func test_takenStatus_2_5hoursBefore_returns_todayTakenTooEarly() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("06:30", on: day5Start) // 2.5 hours before

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTakenTooEarly)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takenTooEarly.text,
            "Taking 2.5 hours before scheduled should show takenTooEarly")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takenTooEarly has no widget-specific text")
    }

    func test_takenStatus_exactly2hoursBefore_boundary() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("07:00", on: day5Start) // Exactly 2 hours before

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTakenTooEarly)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takenTooEarly.text,
            "Taking exactly 2 hours before should show takenTooEarly (boundary)")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takenTooEarly has no widget-specific text")
    }

    func test_takenStatus_atExactScheduledTime_returns_todayTaken() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:00", on: day5Start) // Exact time

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.todayAfter.text,
            "Taking at exact scheduled time should show todayAfter")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Widget should show completion message")
    }

    func test_takenStatus_1hourAfter_returns_todayTaken() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("10:00", on: day5Start) // 1 hour after

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("11:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.todayAfter.text,
            "Taking 1 hour after scheduled should show todayAfter")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Widget should show completion message")
    }

    func test_takenStatus_2_5hoursAfter_returns_todayTakenDelayed() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("11:30", on: day5Start) // 2.5 hours after

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTakenDelayed)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("12:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takenDelayedOk.text,
            "Taking 2.5 hours after scheduled should show takenDelayedOk")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takenDelayedOk has no widget-specific text")
    }

    func test_takenStatus_exactly2hoursAfter_boundary() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("11:00", on: day5Start) // Exactly 2 hours after

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTakenDelayed)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("12:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takenDelayedOk.text,
            "Taking exactly 2 hours after should show takenDelayedOk (boundary)")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takenDelayedOk has no widget-specific text")
    }

    func test_takenStatus_takenDouble_showsTakenDoubleComplete() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.takenDouble)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takenDoubleComplete.text,
            "Taking double should show takenDoubleComplete")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takenDoubleComplete has no widget-specific text")
    }

    func test_takenStatus_checkingImmediatelyAfterTaking() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:05", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("09:06", on: day5Start) // 1 minute after taking
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.todayAfter.text,
            "Checking immediately after taking should show todayAfter")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Widget should show completion message")
    }

    func test_takenStatus_checkingHoursAfterTaking() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("20:00", on: day5Start) // 11 hours after taking
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.todayAfter.text,
            "Checking hours after taking should still show todayAfter")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Widget should show completion message")
    }

    func test_takenStatus_earlyMorning_2amTaken() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("02:00", on: day5Start) // 7 hours before 09:00

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTakenTooEarly)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("10:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takenTooEarly.text,
            "Taking at 2am (7 hours early) should show takenTooEarly")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takenTooEarly has no widget-specific text")
    }

    func test_takenStatus_lateNight_11pmTaken() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("23:00", on: day5Start) // 14 hours after 09:00

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTakenDelayed)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("23:30", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.takenDelayedOk.text,
            "Taking at 11pm (14 hours delayed) should show takenDelayedOk")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "takenDelayedOk has no widget-specific text")
    }

    func test_takenStatus_differentScheduledTime_21_00() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("21:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("21:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("22:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.todayAfter.text,
            "Taking logic should work for any scheduled time (21:00)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Widget should show completion message")
    }

    // MARK: - 6. Before Start Date (5 tests)

    func test_beforeStart_today_D0() {
        // Given
        let startDate = TestConstants.defaultStartDate
        let cycle = CycleBuilder()
            .withStartDate(startDate)
            .build()

        let current = startDate
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, "오늘부터 복용을 시작해요",
            "D-0 should show 'start today' message")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "beforeStart has no widget-specific text")
    }

    func test_beforeStart_tomorrow_D1() {
        // Given
        let startDate = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 1)
        let cycle = CycleBuilder()
            .withStartDate(startDate)
            .build()

        let current = TestConstants.defaultStartDate
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, "내일부터 복용을 시작해요",
            "D-1 should show 'start tomorrow' message")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "beforeStart has no widget-specific text")
    }

    func test_beforeStart_3daysLater_D3() {
        // Given
        let startDate = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let cycle = CycleBuilder()
            .withStartDate(startDate)
            .build()

        let current = TestConstants.defaultStartDate
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, "복용 시작까지 3일 남았어요",
            "D-3 should show '3 days until start' message")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "beforeStart has no widget-specific text")
    }

    func test_beforeStart_7daysLater_D7() {
        // Given
        let startDate = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 7)
        let cycle = CycleBuilder()
            .withStartDate(startDate)
            .build()

        let current = TestConstants.defaultStartDate
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, "복용 시작까지 7일 남았어요",
            "D-7 should show '7 days until start' message")

        // Then - Widget
        XCTAssertNil(result.widgetText,
            "beforeStart has no widget-specific text")
    }

    func test_beforeStart_icon_shouldBeRest() {
        // Given
        let startDate = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let cycle = CycleBuilder()
            .withStartDate(startDate)
            .build()

        let current = TestConstants.defaultStartDate
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.iconImageName, "rest",
            "Before start icon should be rest")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Widget background should be normal")
    }

    // MARK: - 7. 12-Hour Window Logic (10 tests)

    func test_12hourWindow_yesterdayScheduled09_today08_59_usesYesterdayRecord() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4Scheduled = DateTestHelper.makeTime("09:00", on: day4Start)

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("08:59", on: day5Start) // 23h 59m after yesterday's scheduled

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withRecordStatus(day: 4, status: .scheduled)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "Within 12-hour window (11h 59m), should use yesterday's record and show critical delay")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
    }

    func test_12hourWindow_yesterdayScheduled09_today09_00_missed() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("09:00", on: day5Start) // Exactly 24 hours

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withRecordStatus(day: 4, status: .scheduled)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "At exactly 24 hours (new day's scheduled time), should show today's message")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show planting message for new day")
    }

    func test_12hourWindow_yesterdayScheduled09_today10_00_newDay() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("10:00", on: day5Start) // 25 hours after yesterday

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withRecordStatus(day: 4, status: .scheduled)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Beyond 12-hour window, should use today's record")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show today's planting message")
    }

    func test_12hourWindow_yesterdayTaken_todayWithin12hours_usesTodayRecord() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4TakenTime = DateTestHelper.makeTime("09:10", on: day4Start)

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("08:00", on: day5Start) // Before today's scheduled time

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withRecordStatus(day: 4, status: .taken)
            .withTakenAt(day: 4, takenAt: day4TakenTime)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.plantingSeed.text,
            "Yesterday was taken, so should show today's message (not use yesterday's record)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show planting message")
    }

    func test_12hourWindow_yesterdayRest_todayActiveDay() {
        // Given
        let day25Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 24)
        let current = DateTestHelper.makeTime("08:00", on: day25Start)

        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.resting.text,
            "Day 25 is rest period, should not use 12-hour window logic")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Widget should show rest message")
    }

    func test_12hourWindow_yesterdayScheduled_exactly12hours() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4Scheduled = DateTestHelper.makeTime("09:00", on: day4Start)

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.addHours(to: day4Scheduled, hours: 12) // Exactly 12 hours

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withRecordStatus(day: 4, status: .scheduled)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        // At exactly 12 hours, it transitions to missed and shows pilledTwo
        XCTAssertTrue(
            result.text == MessageType.pilledTwo.text || result.text == MessageType.plantingSeed.text,
            "At exactly 12 hours boundary, should transition to new day or show pilledTwo")
    }

    func test_12hourWindow_yesterdayScheduled20_00_today07_59() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4Scheduled = DateTestHelper.makeTime("20:00", on: day4Start)

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("07:59", on: day5Start) // 11h 59m later

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("20:00")
            .withRecordStatus(day: 4, status: .scheduled)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "Within 12-hour window (11h 59m) from 20:00, should show critical delay")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
    }

    func test_12hourWindow_yesterdayScheduled20_00_today08_00_missed() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("08:00", on: day5Start) // Exactly 12 hours from 20:00

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("20:00")
            .withRecordStatus(day: 4, status: .scheduled)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertTrue(
            result.text == MessageType.pilledTwo.text || result.text == MessageType.plantingSeed.text,
            "At 12-hour boundary from 20:00, should transition")
    }

    func test_12hourWindow_crossesMidnight_yesterdayScheduled23_00_today10_59() {
        // Given
        let day4Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 3)
        let day4Scheduled = DateTestHelper.makeTime("23:00", on: day4Start)

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("10:59", on: day5Start) // 11h 59m later, crosses midnight

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("23:00")
            .withRecordStatus(day: 4, status: .scheduled)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertEqual(result.text, MessageType.fire.text,
            "12-hour window crossing midnight should still work (11h 59m)")

        // Then - Widget
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
    }

    func test_12hourWindow_crossesMidnight_yesterdayScheduled23_00_today11_00() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("11:00", on: day5Start) // Exactly 12 hours from 23:00

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("23:00")
            .withRecordStatus(day: 4, status: .scheduled)
            .build()

        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then - Main App
        XCTAssertTrue(
            result.text == MessageType.pilledTwo.text || result.text == MessageType.plantingSeed.text,
            "At exactly 12 hours crossing midnight, should transition")
    }
}
