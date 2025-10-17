//
//  PillingDailyWidgetProvider.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import WidgetKit

// MARK: - PillingDailyWidgetProvider

struct PillingDailyWidgetProvider: TimelineProvider {
    
    private let coreDataManager = SharedCoreDataManager.shared
    private let calculateMessageUseCase = WidgetCalculateMessageUseCase()
    
    // MARK: - TimelineProvider
    
    func placeholder(in context: Context) -> PillingDailyWidgetEntry {
        return .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PillingDailyWidgetEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PillingDailyWidgetEntry>) -> Void) {
        let entry = createEntry()
        
        // 다음 업데이트 시간: 자정
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight) ?? Date()
        
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
    
    // MARK: - Private Methods
    
    private func createEntry() -> PillingDailyWidgetEntry {
        guard let cycle = coreDataManager.fetchCurrentCycle() else {
            return .empty
        }
        
        let messageType = calculateMessageUseCase.execute(cycle: cycle)
        let cycleDay = calculateCycleDay(from: cycle)
        
        let displayData = WidgetDisplayData(
            cycleDay: cycleDay,
            message: messageType.message,
            iconImageName: messageType.iconImageName,
            backgroundImageName: messageType.backgroundImageName
        )
        
        return PillingDailyWidgetEntry(date: Date(), displayData: displayData)
    }
    
    private func calculateCycleDay(from cycle: PillCycle) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: cycle.startDate)
        let today = calendar.startOfDay(for: Date())
        
        guard let days = calendar.dateComponents([.day], from: startDate, to: today).day else {
            return 1
        }
        
        return days + 1 // 1일차부터 시작
    }
}
