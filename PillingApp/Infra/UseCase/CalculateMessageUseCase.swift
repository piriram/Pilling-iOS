import Foundation

final class CalculateMessageUseCase {
    private let statusFactory: PillStatusFactory
    private let ruleEngine: MessageRuleEngine
    private let timeProvider: TimeProvider

    init(statusFactory: PillStatusFactory, timeProvider: TimeProvider) {
        self.statusFactory = statusFactory
        self.timeProvider = timeProvider

        let rules: [MessageRule] = [
            EarlyTakingRule(),
            RestDayRule(),
            ConsecutiveMissedRule(),
            RecentlyMissedRule(),
            DoubleDosingRule(),
            YesterdayMissedRule(),
            TimeBasedRule()
        ]

        self.ruleEngine = MessageRuleEngine(rules: rules)
    }

    func execute(cycle: Cycle?, for date: Date = Date()) -> MessageResult {
        guard let cycle = cycle else {
            return MessageType.empty.toResult()
        }

        if date < cycle.startDate {
            return makeBeforeStartMessage(startDate: cycle.startDate, currentDate: date)
        }

        let context = buildContext(cycle: cycle, date: date)
        let messageType = ruleEngine.evaluate(context: context)

        return messageType.toResult()
    }

    private func buildContext(cycle: Cycle, date: Date) -> MessageContext {
        let todayRecord = findTodayRecord(in: cycle, from: date)
        let yesterdayRecord = findYesterdayRecord(in: cycle, from: date)

        if let today = todayRecord {
            print("🔍 [CalculateMessageUseCase.buildContext] 오늘 레코드")
            print("   DB 상태: \(today.status.rawValue)")
            print("   복용시각: \(today.takenAt?.description ?? "nil")")
            print("   예정시각: \(today.scheduledDateTime)")
        }

        let todayStatus = todayRecord.map { record in
            statusFactory.createStatus(
                scheduledDate: record.scheduledDateTime,
                actionDate: record.takenAt,
                evaluationDate: date,
                isRestDay: record.status == .rest
            )
        }

        let yesterdayStatus = yesterdayRecord.map { record in
            statusFactory.createStatus(
                scheduledDate: record.scheduledDateTime,
                actionDate: record.takenAt,
                evaluationDate: date,
                isRestDay: record.status == .rest
            )
        }

        let consecutiveMissed = calculateConsecutiveMissedDays(
            cycle: cycle,
            upTo: date
        )

        return MessageContext(
            todayStatus: todayStatus,
            yesterdayStatus: yesterdayStatus,
            cycle: cycle,
            currentDate: date,
            consecutiveMissedDays: consecutiveMissed,
            timeProvider: timeProvider
        )
    }

    private func findTodayRecord(in cycle: Cycle, from date: Date) -> DayRecord? {
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: date)
        }
    }

    private func findYesterdayRecord(in cycle: Cycle, from date: Date) -> DayRecord? {
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: yesterday)
        }
    }

    private func calculateConsecutiveMissedDays(cycle: Cycle, upTo targetDate: Date) -> Int {
        var count = 0
        
        let sortedRecords = cycle.records.sorted {
            $0.scheduledDateTime > $1.scheduledDateTime
        }

        for record in sortedRecords {
            let timeElapsed = targetDate.timeIntervalSince(record.scheduledDateTime)

            if timeElapsed >= TimeThreshold.fullyMissed && !record.status.isTaken {
                count += 1
            } else if record.status.isTaken {
                break
            }
            print("연속:\(count)")
        }

        return count
    }

    private func makeBeforeStartMessage(startDate: Date, currentDate: Date) -> MessageResult {
        let components = timeProvider.calendar.dateComponents([.day], from: currentDate, to: startDate)

        guard let daysUntilStart = components.day else {
            return MessageType.beforeStart(daysUntilStart: 0).toResult()
        }

        return MessageType.beforeStart(daysUntilStart: daysUntilStart).toResult()
    }
}
