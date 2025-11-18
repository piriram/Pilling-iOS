//
//  CalculateMessageUseCaseWidgetTests.swift
//  PillingAppTests
//
//  Widget-specific tests for CalculateMessageUseCase
//  Verifies widget text, backgrounds, and timeline scenarios
//

import XCTest
@testable import PillingApp

/// Widget-specific tests for timeline updates and widget-specific data
final class CalculateMessageUseCaseWidgetTests: XCTestCase {

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

    // MARK: - 1. Widget Text Verification (15 tests)

    func test_widget_beforeTaking_showsPlantingSeedMessage() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("08:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.plantingSeed.text)
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Widget should show specific short message")
    }

    func test_widget_afterTaking_showsTodayAfterMessage() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

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

        // Then
        XCTAssertEqual(result.text, MessageType.todayAfter.text)
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Widget should show completion message")
    }

    func test_widget_2daysMissed_showsWaitingMessage() {
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

        // Then
        XCTAssertEqual(result.text, MessageType.waiting.text)
        XCTAssertEqual(result.widgetText, "잔디가 기다려요",
            "Widget should show waiting message for consecutive missed")
    }

    func test_widget_2hoursDelayed_showsGroomyMessage() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("11:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.groomy.text)
        XCTAssertEqual(result.widgetText, "2시간 지났어요!",
            "Widget should show 2-hour delay message")
    }

    func test_widget_4hoursDelayed_showsFireMessage() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("13:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.fire.text)
        XCTAssertEqual(result.widgetText, "4시간 지났어요!",
            "Widget should show 4-hour delay message")
    }

    func test_widget_restPeriod_showsRestMessage() {
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

        // Then
        XCTAssertEqual(result.text, MessageType.resting.text)
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Widget should show rest message")
    }

    func test_widget_nilWidgetText_fallbackToMainText() {
        // Given - States with nil widgetText (like success, pilledTwo, etc.)
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

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

        // Then
        XCTAssertEqual(result.text, MessageType.success.text)
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for success (fallback to main text)")
    }

    func test_widget_pilledTwo_nilWidgetText() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .yesterdayStatus(.missed)
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("08:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.pilledTwo.text)
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for pilledTwo")
    }

    func test_widget_takingBefore_nilWidgetText() {
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

        // Then
        XCTAssertEqual(result.text, MessageType.takingBefore.text)
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for takingBefore")
    }

    func test_widget_warning_nilWidgetText() {
        // Given - This is harder to trigger, but let's test the enum directly
        let result = MessageType.warning.toResult()

        // Then
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for warning")
    }

    func test_widget_takenDelayedOk_nilWidgetText() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("11:30", on: day5Start)

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

        // Then
        XCTAssertEqual(result.text, MessageType.takenDelayedOk.text)
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for takenDelayedOk")
    }

    func test_widget_takenTooEarly_nilWidgetText() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("06:30", on: day5Start)

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

        // Then
        XCTAssertEqual(result.text, MessageType.takenTooEarly.text)
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for takenTooEarly")
    }

    func test_widget_takenDoubleComplete_nilWidgetText() {
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

        // Then
        XCTAssertEqual(result.text, MessageType.takenDoubleComplete.text)
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for takenDoubleComplete")
    }

    func test_widget_beforeStart_nilWidgetText() {
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
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for beforeStart")
    }

    func test_widget_empty_nilWidgetText() {
        // Given - nil cycle
        let current = TestConstants.defaultStartDate
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: nil, for: current)

        // Then
        XCTAssertEqual(result.text, MessageType.empty.text)
        XCTAssertNil(result.widgetText,
            "Widget text should be nil for empty")
    }

    // MARK: - 2. Widget Background Image Tests (10 tests)

    func test_widgetBackground_normalStatus_normalBackground() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("08:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Normal status should use normal background")
    }

    func test_widgetBackground_2daysMissed_warningBackground() {
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

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_warning",
            "Consecutive missed should use warning background")
    }

    func test_widgetBackground_2hoursDelayed_groomyBackground() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("11:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_groomy",
            "2-hour delay should use groomy background")
    }

    func test_widgetBackground_4hoursDelayed_fireBackground() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("13:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_fire",
            "4-hour delay should use fire background")
    }

    func test_widgetBackground_restPeriod_normalBackground() {
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

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Rest period should use normal background")
    }

    func test_widgetBackground_todayTaken_normalBackground() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:10", on: day5Start)

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

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Taken status should use normal background")
    }

    func test_widgetBackground_consecutiveMissedTakesPriorityOverDelay() {
        // Given - 2 days missed + 2 hours delayed
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

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_warning",
            "Consecutive missed should take priority over delay background")
    }

    func test_widgetBackground_3daysMissed_warningBackground() {
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

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_warning",
            "3 consecutive missed should use warning background")
    }

    func test_widgetBackground_beforeStart_normalBackground() {
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
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Before start should use normal background")
    }

    func test_widgetBackground_empty_normalBackground() {
        // Given - nil cycle
        let current = TestConstants.defaultStartDate
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: nil, for: current)

        // Then
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal",
            "Empty should use normal background")
    }

    // MARK: - 3. Widget Timeline Scenarios (5 tests)

    func test_widgetTimeline_morningUpdate_beforeScheduled() {
        // Given - Widget updates at 07:00 (before 09:00 scheduled)
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("07:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.widgetText, "잔디를 심어보세요!",
            "Morning update should show planting message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal")
    }

    func test_widgetTimeline_rightAfterTaking() {
        // Given - Widget updates at 09:10 (just taken)
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:05", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("09:10", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Right after taking should show completion message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal")
    }

    func test_widgetTimeline_eveningUpdate_alreadyTaken() {
        // Given - Widget updates at 20:00 (taken at 09:05)
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let takenTime = DateTestHelper.makeTime("09:05", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: takenTime)
            .build()

        let current = DateTestHelper.makeTime("20:00", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.widgetText, "잔디 심기 완료!",
            "Evening update should still show completion message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal")
    }

    func test_widgetTimeline_delayedUpdate() {
        // Given - Widget updates at 11:30 (2.5 hours delayed)
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let current = DateTestHelper.makeTime("11:30", on: day5Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.widgetText, "2시간 지났어요!",
            "Delayed update should show 2-hour delay message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_groomy")
    }

    func test_widgetTimeline_restPeriodUpdate() {
        // Given - Widget updates on Day 25 (any time)
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let day25Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 24)
        let current = DateTestHelper.makeTime("14:30", on: day25Start)
        mockTimeProvider.now = current

        // When
        let result = sut.execute(cycle: cycle, for: current)

        // Then
        XCTAssertEqual(result.widgetText, "지금은 쉬는 시간",
            "Rest period update should show rest message")
        XCTAssertEqual(result.backgroundImageName, "widget_background_normal")
    }
}
