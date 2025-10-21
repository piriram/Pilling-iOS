//
//  PillStatusEvaluator.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/21/25.
//

import Foundation

final class PillStatusEvaluator {
    
    private enum Constants {
        static let twelveHours: TimeInterval = 12 * 60 * 60
        static let twoHours: TimeInterval = 2 * 60 * 60
        static let fourHours: TimeInterval = 4 * 60 * 60
        static let missedStreakThreshold = 2
    }
    
    private let timeProvider: TimeProvider
    
    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }
    
    // MARK: - Public
    
    func evaluate<T: PillStatusItem>(
        cycle: PillCycle?,
        items: [T],
        at date: Date
    ) -> PillMessageDecision {
        guard !items.isEmpty else {
            return .empty
        }
        
        guard let todayItem = findRelevantItem(items: items, for: date) else {
            return handleNoTodayItem(items: items, for: date)
        }
        
        if case .rest = todayItem.status {
            return .resting
        }
        
        if isTodayRelatedStatus(todayItem.status) {
            // 연속 미복용 체크
            if let decision = handleConsecutiveMissed(
                todayItem: todayItem,
                cycle: cycle,
                at: date
            ) {
                return decision
            }
            
            // 어제 미복용 체크
            if let decision = handleYesterdayMissed(
                todayItem: todayItem,
                items: items,
                cycle: cycle,
                at: date
            ) {
                return decision
            }
        }
        
        return mapStatusToDecision(todayItem.status)
    }
    
    // MARK: - Private Helpers
    
    private func findRelevantItem<T: PillStatusItem>(
        items: [T],
        for date: Date
    ) -> T? {
        // 오늘 날짜의 아이템
        if let todayItem = items.first(where: {
            timeProvider.isDate($0.scheduledDateTime, inSameDayAs: date)
        }) {
            return todayItem
        }
        
        // 어제 아이템이 12시간 윈도우 내인지
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: date),
              let yesterdayItem = items.first(where: {
                  timeProvider.isDate($0.scheduledDateTime, inSameDayAs: yesterday)
              }) else {
            return nil
        }
        
        let timeSinceScheduled = date.timeIntervalSince(yesterdayItem.scheduledDateTime)
        
        if timeSinceScheduled < Constants.twelveHours,
           !yesterdayItem.status.isTaken,
           yesterdayItem.status != .rest {
            return yesterdayItem
        }
        
        return nil
    }
    
    private func handleNoTodayItem<T: PillStatusItem>(
        items: [T],
        for date: Date
    ) -> PillMessageDecision {
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: date),
              let yesterdayItem = items.first(where: {
                  timeProvider.isDate($0.scheduledDateTime, inSameDayAs: yesterday)
              }) else {
            return .resting
        }
        
        let timeSinceScheduled = date.timeIntervalSince(yesterdayItem.scheduledDateTime)
        
        if timeSinceScheduled >= Constants.twelveHours,
           !yesterdayItem.status.isTaken,
           yesterdayItem.status != .rest {
            return .oneMorePill
        }
        
        return .resting
    }
    
    private func handleConsecutiveMissed<T: PillStatusItem>(
        todayItem: T,
        cycle: PillCycle?,
        at date: Date
    ) -> PillMessageDecision? {
        let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle, upTo: date)
        
        guard consecutiveMissed >= Constants.missedStreakThreshold else {
            return nil
        }
        
        if todayItem.status == .todayTaken ||
           todayItem.status == .todayTakenDelayed ||
           todayItem.status == .todayTakenTooEarly {
            return .success
        }
        
        return .waiting
    }
    
    private func handleYesterdayMissed<T: PillStatusItem>(
        todayItem: T,
        items: [T],
        cycle: PillCycle?,
        at date: Date
    ) -> PillMessageDecision? {
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: date),
              let yesterdayItem = items.first(where: {
                  timeProvider.isDate($0.scheduledDateTime, inSameDayAs: yesterday)
              }) else {
            return nil
        }
        
        guard case .missed = yesterdayItem.status else {
            return nil
        }
        
        let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle, upTo: date)
        
        // 어제 미복용 + 연속 1일 + 오늘 복용 완료
        if consecutiveMissed == 1,
           (todayItem.status == .todayTaken ||
            todayItem.status == .todayTakenDelayed ||
            todayItem.status == .todayTakenTooEarly) {
            return .oneMorePill
        }
        
        // 어제 미복용 + 오늘 2알 복용
        if case .takenDouble = todayItem.status {
            return .success
        }
        
        // 어제 미복용 + 오늘 1알만 복용
        if todayItem.status == .todayTaken || todayItem.status == .takenTooEarly {
            return .oneMorePill
        }
        
        // 어제 미복용 + 오늘 아직 복용 안함
        return .yesterdayMissed
    }
    
    private func isTodayRelatedStatus(_ status: PillStatus) -> Bool {
        switch status {
        case .todayDelayed, .todayDelayedCritical, .todayNotTaken,
             .todayTakenDelayed, .todayTakenTooEarly, .todayTaken:
            return true
        default:
            return false
        }
    }
    
    private func calculateConsecutiveMissedDays(
        cycle: PillCycle?,
        upTo targetDate: Date
    ) -> Int {
        guard let cycle = cycle else { return 0 }
        
        let today = timeProvider.startOfDay(for: targetDate)
        var count = 0
        
        for record in cycle.records.reversed() {
            let recordDay = timeProvider.startOfDay(for: record.scheduledDateTime)
            
            guard recordDay < today else { continue }
            
            if case .rest = record.status {
                continue
            }
            
            let timeSinceScheduled = targetDate.timeIntervalSince(record.scheduledDateTime)
            
            if timeSinceScheduled >= Constants.twelveHours, !record.status.isTaken {
                count += 1
            } else if record.status.isTaken {
                break
            }
        }
        
        return count
    }
    
    private func mapStatusToDecision(_ status: PillStatus) -> PillMessageDecision {
        switch status {
        case .todayTaken:
            return .success
        case .todayTakenDelayed:
            return .successDelayed
        case .todayTakenTooEarly:
            return .successTooEarly
        case .todayDelayed:
            return .groomy
        case .todayDelayedCritical:
            return .fire
        case .takenDouble:
            return .successDouble
        case .todayNotTaken:
            return .plantingSeed
        case .taken, .takenDelayed, .missed, .scheduled, .takenTooEarly:
            return .resting
        case .rest:
            return .resting
        }
    }
}

// MARK: - PillMessageDecision

enum PillMessageDecision {
    case empty
    case resting
    case oneMorePill
    case waiting
    case success
    case groomy
    case fire
    case yesterdayMissed
    case plantingSeed
    case successDelayed
    case successTooEarly
    case successDouble
    
    func toDashboardMessage() -> DashboardMessage {
        switch self {
        case .empty:
            return DashboardMessage(text: "...", imageName: .rest, icon: .rest)
        case .resting:
            return DashboardMessage(text: "오늘은 잔디도 휴식중", imageName: .rest, icon: .rest)
        case .oneMorePill:
            return DashboardMessage(text: "오늘은 두알을 복용하세요.", imageName: .fire, icon: .notTaken)
        case .waiting:
            return DashboardMessage(text: "저를 잊었나요...?", imageName: .warning, icon: .missed)
        case .success:
            return DashboardMessage(text: "꾸준히 잔디를 심어주세요.", imageName: .takingBefore, icon: .taken)
        case .groomy:
            return DashboardMessage(text: "잔디는 2시간을 초과하지 않게 심어주세요!", imageName: .groomy, icon: .missed)
        case .fire:
            return DashboardMessage(text: "복용 시간이 4시간 이상 지났어요", imageName: .fire, icon: .notTaken)
        case .yesterdayMissed:
            return DashboardMessage(text: "오늘은 두알을 복용하세요.", imageName: .fire, icon: .notTaken)
        case .plantingSeed:
            return DashboardMessage(text: "오늘의 잔디를 심어주세요", imageName: .takingBefore, icon: .notTaken)
        case .successDelayed:
            return DashboardMessage(text: "2시간 지났지만 괜찮아요!", imageName: .todayAfter, icon: .taken)
        case .successTooEarly:
            return DashboardMessage(text: "예정보다 2시간 이상 일찍 복용했어요", imageName: .todayAfter, icon: .taken)
        case .successDouble:
            return DashboardMessage(text: "내일의 잔디도 부탁해요.", imageName: .todayAfter, icon: .taken)
        }
    }
    
    func toWidgetMessageType() -> WidgetMessageType {
        switch self {
        case .empty:
            return .empty
        case .resting:
            return .resting
        case .oneMorePill:
            return .oneMorePill
        case .waiting:
            return .waiting
        case .success, .successDelayed, .successTooEarly, .successDouble:
            return .success
        case .groomy:
            return .groomy
        case .fire:
            return .fire
        case .yesterdayMissed:
            return .yesterdayMissed
        case .plantingSeed:
            return .plantingSeed
        }
    }
}
