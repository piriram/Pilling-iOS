//
//  PillingDailyWidgetProvider.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/17/25.
//
import WidgetKit

struct PillingDailyWidgetProvider: TimelineProvider {
    private let timeProvider: TimeProvider
    private let coreDataManager = SharedCoreDataManager.shared
    private let calculateMessageUseCase = WidgetCalculateMessageUseCase()

    // 편의 이니셜라이저 (기본 SystemTimeProvider)
    init(timeProvider: TimeProvider = SystemTimeProvider()) {
        self.timeProvider = timeProvider
    }

    func placeholder(in context: Context) -> PillingDailyWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PillingDailyWidgetEntry) -> Void) {
        guard let cycle = coreDataManager.fetchCurrentCycle(timeProvider: timeProvider) else {
            completion(.empty)
            return
        }
        let entry = createEntry(for: timeProvider.now, cycle: cycle)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PillingDailyWidgetEntry>) -> Void) {
        var entries: [PillingDailyWidgetEntry] = []
        let cal = timeProvider.calendar
        let now = timeProvider.now

        guard let cycle = coreDataManager.fetchCurrentCycle(timeProvider: timeProvider) else {
            let nextUpdate = cal.date(byAdding: .hour, value: 1, to: now) ?? now
            entries.append(.empty)
            completion(Timeline(entries: entries, policy: .after(nextUpdate)))
            return
        }

        // 오늘 0시 기준으로 7일치
        let todayStart = timeProvider.startOfDay(for: now)
        for dayOffset in 0..<7 {
            guard let targetDate = cal.date(byAdding: .day, value: dayOffset, to: todayStart) else { continue }

            if let scheduledTime = getScheduledTime(for: targetDate, cycle: cycle, calendar: cal) {
                // 정시
                entries.append(createEntry(for: scheduledTime, cycle: cycle))
                // +2h / +4h / +12h
                if let t2h = cal.date(byAdding: .hour, value: 2, to: scheduledTime) {
                    entries.append(createEntry(for: t2h, cycle: cycle))
                }
                if let t4h = cal.date(byAdding: .hour, value: 4, to: scheduledTime) {
                    entries.append(createEntry(for: t4h, cycle: cycle))
                }
                if let t12h = cal.date(byAdding: .hour, value: 12, to: scheduledTime) {
                    entries.append(createEntry(for: t12h, cycle: cycle))
                }
            } else {
                // 휴약일 등: 하루 1번
                entries.append(createEntry(for: targetDate, cycle: cycle))
            }
        }

        if entries.isEmpty { entries.append(.empty) }
        entries.sort { $0.date < $1.date }

        // 다음 업데이트 시점
        let nextUpdate = cal.date(byAdding: .day, value: 7, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }

    // MARK: - Private

    private func getScheduledTime(for date: Date, cycle: PillCycle, calendar: Calendar) -> Date? {
        guard let record = cycle.records.first(where: { calendar.isDate($0.scheduledDateTime, inSameDayAs: date) }) else { return nil }
        if case .rest = record.status { return nil }
        return record.scheduledDateTime
    }

    private func createEntry(for date: Date, cycle: PillCycle) -> PillingDailyWidgetEntry {
        let messageType = calculateMessageUseCase.execute(cycle: cycle, for: date)
        let cycleDay = calculateCycleDay(from: cycle, for: date)
        let displayData = WidgetDisplayData(
            cycleDay: cycleDay,
            message: messageType.message,
            iconImageName: messageType.iconImageName,
            backgroundImageName: messageType.backgroundImageName
        )
        return PillingDailyWidgetEntry(date: date, displayData: displayData)
    }

    private func calculateCycleDay(from cycle: PillCycle, for date: Date) -> Int {
        let cal = timeProvider.calendar
        let start = timeProvider.startOfDay(for: cycle.startDate)
        let target = timeProvider.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: start, to: target).day ?? 0
        return days + 1
    }
}
