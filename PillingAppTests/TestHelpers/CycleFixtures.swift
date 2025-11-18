//
//  CycleFixtures.swift
//  PillingAppTests
//
//  Preset cycle fixtures for common test scenarios
//

import Foundation
@testable import PillingApp

/// Preset cycle fixtures for tests
struct CycleFixtures {

    // MARK: - Basic Cycles

    /// Standard 24-4 cycle (24 active days, 4 break days)
    static var standard_24_4: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .build()
    }

    /// Standard cycle at day 5 (mid-cycle)
    static var day5: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(5)
            .build()
    }

    /// Standard cycle at day 1 (first day)
    static var day1: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(1)
            .build()
    }

    /// Standard cycle at day 24 (last active day)
    static var day24LastActive: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(24)
            .build()
    }

    // MARK: - Rest Period Cycles

    /// Cycle at day 25 (first rest day)
    static var restPeriodDay25: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(25)
            .build()
    }

    /// Cycle at day 26 (second rest day)
    static var restPeriodDay26: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(26)
            .build()
    }

    /// Cycle at day 27 (third rest day)
    static var restPeriodDay27: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(27)
            .build()
    }

    /// Cycle at day 28 (last rest day)
    static var restPeriodDay28: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(28)
            .build()
    }

    // MARK: - Consecutive Missed Cycles

    /// Cycle with 1 day missed (day 4 missed, current day 5)
    static var consecutiveMissed1Day: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(5)
            .withConsecutiveMissedDays(1)
            .build()
    }

    /// Cycle with 2 consecutive missed days
    static var consecutiveMissed2Days: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(5)
            .withConsecutiveMissedDays(2)
            .build()
    }

    /// Cycle with 3 consecutive missed days
    static var consecutiveMissed3Days: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(6)
            .withConsecutiveMissedDays(3)
            .build()
    }

    // MARK: - Yesterday Missed Scenarios

    /// Yesterday missed, today taken (need 1 more pill)
    static var yesterdayMissedTodayTaken: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(5)
            .yesterdayStatus(.missed)
            .todayStatus(.todayTaken)
            .build()
    }

    /// Yesterday missed, today taken double (correctly compensated)
    static var yesterdayMissedTodayDouble: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(5)
            .yesterdayStatus(.missed)
            .todayStatus(.takenDouble)
            .build()
    }

    /// Yesterday missed, today not taken yet
    static var yesterdayMissedTodayNotTaken: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withCurrentDay(5)
            .yesterdayStatus(.missed)
            .todayStatus(.todayNotTaken)
            .build()
    }

    // MARK: - Before Start Date

    /// Cycle that starts in 3 days
    static func beforeStart(daysUntilStart: Int) -> Cycle {
        let futureStartDate = DateTestHelper.addDays(
            to: TestConstants.defaultStartDate,
            days: daysUntilStart
        )

        return CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("09:00")
            .withStartDate(futureStartDate)
            .build()
    }

    // MARK: - Different Scheduled Times

    /// Cycle with scheduled time at 21:00 (for midnight crossing tests)
    static var eveningSchedule: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("21:00")
            .withCurrentDay(5)
            .build()
    }

    /// Cycle with scheduled time at 23:00 (for midnight boundary tests)
    static var lateNightSchedule: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("23:00")
            .withCurrentDay(5)
            .build()
    }

    /// Cycle with scheduled time at 06:00 (early morning)
    static var earlyMorningSchedule: Cycle {
        CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .withScheduledTime("06:00")
            .withCurrentDay(5)
            .build()
    }
}
