# PillingApp Test Suite v3.0

Comprehensive test suite for PillingApp contraceptive pill tracking application.

## Overview

This test suite implements **CTest v3.0** with complete coverage of:
- ✅ Core business logic (time-based status transitions)
- ✅ Widget integration and data consistency
- ✅ Timezone handling across 6 major timezones
- ✅ Medical accuracy verification (2h, 4h, 12h thresholds)
- ✅ Rest period bug fix validation
- ✅ Consecutive missed logic
- ✅ 12-hour window handling
- ✅ PillStatus adjustment methods
- ✅ UpdatePillStatusUseCase functionality

## Test Statistics

- **Total Tests**: 180+
- **Total Lines**: ~3,900
- **Test Execution Time**: 6-10 seconds
- **Target Coverage**:
  - CalculateMessageUseCase: 95%+
  - PillStatus: 100%
  - Overall: 35-45%

## Test Infrastructure

### Core Test Helpers

#### MockTimeProvider
Complete control over time and timezone for deterministic testing.

```swift
let mockTime = MockTimeProvider(now: testDate, timeZone: TimeZone(identifier: "Asia/Seoul")!)
mockTime.changeTimeZone(to: TimeZone(identifier: "America/New_York")!)
```

#### CycleBuilder (⭐ CORE)
Fluent API for easy test data generation. Add new test data in under 5 minutes!

```swift
let cycle = CycleBuilder()
    .day(5)
    .scheduledTime("09:00")
    .yesterdayStatus(.missed)
    .todayStatus(.takenDouble)
    .build()
```

#### TimeScenario
Easy creation of time-based test scenarios.

```swift
let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "11:00")
// Returns: (scheduled: Date, current: Date)
```

#### CycleFixtures
Preset test data for common scenarios.

```swift
let cycle = CycleFixtures.restPeriodDay25  // Pre-built rest period cycle
let cycle = CycleFixtures.consecutiveMissed2Days  // 2 days missed
let cycle = CycleFixtures.yesterdayMissedTodayDouble  // Yesterday missed logic
```

## Test Structure

```
PillingAppTests/
├── Mocks/
│   ├── MockTimeProvider.swift (80 lines)
│   └── MockCycleRepository.swift (60 lines)
├── TestHelpers/
│   ├── DateTestHelper.swift (150 lines)
│   ├── CycleBuilder.swift (300 lines) ⭐ CORE
│   ├── TimeScenario.swift (100 lines)
│   ├── CycleFixtures.swift (200 lines)
│   ├── TestConstants.swift (30 lines)
│   └── InfrastructureVerificationTests.swift (120 lines)
├── UseCaseTests/
│   ├── CalculateMessageUseCaseTests.swift (2600+ lines, 100+ tests)
│   ├── CalculateMessageUseCaseTimeZoneTests.swift (400 lines, 20+ tests)
│   ├── CalculateMessageUseCaseWidgetTests.swift (400 lines, 30 tests)
│   └── UpdatePillStatusUseCaseTests.swift (200 lines, 15 tests)
└── ModelTests/
    └── PillStatusTests.swift (300 lines, 30 tests)
```

## Test Categories

### Phase 1: Core Business Logic (100+ tests)

#### 1. Time Threshold Tests (20 tests)
Verifies medical accuracy of 2h, 4h, and 12h thresholds.

- ✅ Before scheduled time → `todayNotTaken`
- ✅ +2 hours → `todayDelayed` (groomy)
- ✅ +4 hours → `todayDelayedCritical` (fire)
- ✅ +12 hours → `missed` / `pilledTwo`
- ✅ Boundary tests (±1 minute)
- ✅ Widget text and background verification

#### 2. Rest Period Tests (15 tests) ⚠️ BUG FIX TARGET
Confirms rest period identification bug is fixed.

- ✅ Day 24 (last active) → NOT rest
- ✅ Day 25 (first rest) → IS rest ⭐ CRITICAL
- ✅ Days 26-28 → rest
- ✅ Midnight boundary (23:59 vs 00:00)
- ✅ Different scheduled times
- ✅ Widget integration

#### 3. Consecutive Missed Logic (15 tests)
Tests complex multi-day missed scenarios.

- ✅ 1 day missed → normal messages
- ✅ 2+ days missed → waiting message
- ✅ 2 days missed + today taken → success
- ✅ Rest days excluded from count
- ✅ Priority over delay messages
- ✅ Widget backgrounds

#### 4. Yesterday Missed + Today Status (25 tests)
Tests double pill protocol and warning logic.

- ✅ Yesterday missed + today 2 pills → takingBefore
- ✅ Yesterday missed + today 1 pill → warning
- ✅ Yesterday missed + today not taken → pilledTwo
- ✅ All delay combinations
- ✅ Widget integration

#### 5. Taken Status After Taking (15 tests)
Verifies status after pill is taken.

- ✅ Within 2 hours early → todayTaken
- ✅ 2+ hours early → todayTakenTooEarly
- ✅ 2+ hours late → todayTakenDelayed
- ✅ Double pill → takenDoubleComplete
- ✅ Widget completion messages

#### 6. Before Start Date (5 tests)
Tests cycle not yet started.

- ✅ D-0: "오늘부터 복용을 시작해요"
- ✅ D-1: "내일부터 복용을 시작해요"
- ✅ D-3, D-7: Day counts

#### 7. 12-Hour Window Logic (10 tests)
Verifies yesterday's record can be used within 12 hours.

- ✅ 11h 59m → use yesterday's record
- ✅ 12h exact → transition to today
- ✅ Midnight crossing
- ✅ Different scheduled times

### Phase 2: Timezone Tests (20+ tests)

#### Same Logic Across Timezones (18 tests)
Verifies consistency across 6 timezones:

- ✅ UTC
- ✅ Asia/Seoul (KST)
- ✅ America/New_York (EST)
- ✅ Europe/London (GMT)
- ✅ Australia/Sydney (AEDT)
- ✅ Pacific/Honolulu (HST)

#### Midnight Boundary Tests (20 tests)
Critical timezone-aware midnight transitions.

- ✅ 23:59 vs 00:00 in all timezones
- ✅ 12-hour window crossing midnight
- ✅ Rest period boundary with timezone

#### Timezone Change Simulation (5 tests)
Simulates international travel.

- ✅ Seoul → New York travel
- ✅ Local time calculation after timezone change

### Phase 3: Widget-Specific Tests (30 tests)

#### Widget Text Verification (15 tests)
Verifies widget-specific short messages.

- ✅ States with widget text:
  - plantingSeed: "잔디를 심어보세요!"
  - todayAfter: "잔디 심기 완료!"
  - waiting: "잔디가 기다려요"
  - groomy: "2시간 지났어요!"
  - fire: "4시간 지났어요!"
  - resting: "지금은 쉬는 시간"
- ✅ States with nil (fallback to main text)

#### Widget Background Tests (10 tests)
Verifies widget-specific backgrounds.

- ✅ Normal: "widget_background_normal"
- ✅ Warning (consecutive missed): "widget_background_warning"
- ✅ Groomy (2h delay): "widget_background_groomy"
- ✅ Fire (4h delay): "widget_background_fire"
- ✅ Priority rules

#### Widget Timeline Scenarios (5 tests)
Tests widget updates at different times.

- ✅ Morning update (before scheduled)
- ✅ Right after taking
- ✅ Evening update (already taken)
- ✅ Delayed update
- ✅ Rest period update

### Phase 4: PillStatus Tests (30 tests)

Tests `adjustedForDate` method.

- ✅ Today conversions (taken → todayTaken)
- ✅ Past conversions (todayTaken → taken)
- ✅ Missed conversions
- ✅ Rest always remains rest
- ✅ isToday property

### Phase 5: UpdatePillStatusUseCase Tests (15 tests)

Tests status update functionality.

- ✅ Status update
- ✅ Memo update
- ✅ TakenAt update
- ✅ Invalid index handling
- ✅ Property preservation

## Running Tests

### Xcode
1. Select PillingAppTests scheme
2. Press `Cmd + U` or Product → Test
3. View results in Test Navigator

### Command Line
```bash
xcodebuild test \
  -project PillingApp.xcodeproj \
  -scheme PillingAppTests \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Expected Results
```
Test Suite 'All tests' passed at [timestamp]
Executed 180+ tests, with 0 failures (0 unexpected) in 6-10 seconds
```

## Test Principles

### Given-When-Then Pattern
```swift
func test_2hourDelayed_returns_todayDelayed_status() {
    // Given: Prepare test data
    let cycle = CycleBuilder().day(5).scheduledTime("09:00").build()
    let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "11:00")
    mockTimeProvider.now = scenario.current

    // When: Execute logic
    let result = sut.execute(cycle: cycle, for: scenario.current)

    // Then: Verify results
    // Main App
    XCTAssertEqual(result.text, MessageType.groomy.text)

    // Widget (CRITICAL: verify widget data too!)
    XCTAssertEqual(result.widgetText, "2시간 지났어요!")
    XCTAssertEqual(result.backgroundImageName, "widget_background_groomy")
}
```

### No Hardcoding
❌ **Bad:**
```swift
XCTAssertEqual(result.text, "잔디는 2시간을 초과하지 않게 심어주세요!")
```

✅ **Good:**
```swift
XCTAssertEqual(result.text, MessageType.groomy.text)
```

### Widget Assertions Required
Every test that calls `CalculateMessageUseCase.execute()` MUST verify:
1. `result.text` (main app)
2. `result.widgetText` (widget)
3. `result.backgroundImageName` (widget)

This ensures widget and main app stay synchronized.

## Adding New Tests

### 1. Use CycleBuilder
```swift
let cycle = CycleBuilder()
    .day(7)
    .scheduledTime("21:00")
    .yesterdayStatus(.missed)
    .withConsecutiveMissedDays(2)
    .build()
```

### 2. Use TimeScenario
```swift
let scenario = TimeScenario.make(scheduledTime: "09:00", currentTime: "13:00")
```

### 3. Set MockTimeProvider
```swift
mockTimeProvider.now = scenario.current
```

### 4. Verify Main App + Widget
```swift
// Main App
XCTAssertEqual(result.text, MessageType.fire.text)

// Widget
XCTAssertEqual(result.widgetText, "4시간 지났어요!")
XCTAssertEqual(result.backgroundImageName, "widget_background_fire")
```

## Bug Fixes Verified

### ✅ Rest Period Bug
**Issue**: Day 24 incorrectly showed as rest period
**Fix**: Day 25 is first rest day (activeDays + 1)
**Verification**: `test_restPeriod_day24_lastActiveDay_notRest()`

### ✅ Consecutive Missed Priority
**Issue**: Delay messages shown instead of waiting
**Fix**: Consecutive missed takes priority
**Verification**: `test_consecutiveMissed_2days_at2hourDelay_prioritizesWaiting()`

## Coverage Report

Expected coverage after running all tests:

```
CalculateMessageUseCase: 95%+
├── Time thresholds: 100%
├── Rest period logic: 100%
├── Consecutive missed: 100%
├── 12-hour window: 100%
└── Before start date: 100%

PillStatus: 100%
├── adjustedForDate: 100%
├── isToday: 100%
└── isTaken: 100%

UpdatePillStatusUseCase: 90%+
├── Status update: 100%
├── Memo update: 100%
└── TakenAt update: 100%

Overall Project: 35-45%
```

## Portfolio Highlights

### Technical Achievements
- ✅ Medical accuracy verification (2h, 4h, 12h thresholds)
- ✅ Complex business logic testing (consecutive missed, double pill)
- ✅ Complete time control via MockTimeProvider
- ✅ 6 timezone internationalization
- ✅ Midnight boundary handling across timezones
- ✅ Widget-app data synchronization verification
- ✅ Builder pattern for maintainable test data
- ✅ Real bug discovery and fix validation

### Maintainability
- Add new test data in **under 5 minutes** using CycleBuilder
- No hardcoded strings - all use enum values
- Clear Given-When-Then structure
- Comprehensive assertions (main app + widget)

### Test Quality
- 180+ tests covering critical medical logic
- Executes in 6-10 seconds
- Independent, deterministic tests
- Widget integration verified in every test

## Best Practices

### ✅ DO
- Use CycleBuilder for all test data
- Use TimeScenario for time-based scenarios
- Verify both main app AND widget data
- Use MockTimeProvider for time control
- Add descriptive failure messages
- Follow Given-When-Then pattern

### ❌ DON'T
- Never use actual `Date()` in tests
- Never hardcode message strings
- Never skip widget assertions
- Never create test dependencies
- Never use `Thread.sleep()`
- Never create Cycle manually without Builder

## Future Enhancements

Potential additions:
- [ ] Performance tests (execution time)
- [ ] Stress tests (100+ day cycles)
- [ ] Daylight Saving Time edge cases
- [ ] Snapshot tests for widget UI
- [ ] Integration tests with CoreData
- [ ] Accessibility tests

## License

Same as main project (see root LICENSE file).

## Authors

Created as part of CTest v3.0 implementation for PillingApp.

---

**Last Updated**: 2025-11-18
**Test Suite Version**: 3.0
**Minimum iOS**: 16.0
