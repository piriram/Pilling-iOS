//
//  WidgetCalculateMessageUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import Foundation

// MARK: - WidgetCalculateMessageUseCase

final class WidgetCalculateMessageUseCase {
    
    private let timeProvider: TimeProvider
    
    init(timeProvider: TimeProvider = SystemTimeProvider()) {
        self.timeProvider = timeProvider
    }
    
    // MARK: - Execute
    
    func execute(cycle: PillCycle?) -> WidgetMessageType {
        guard let cycle = cycle else {
            return .empty
        }
        
        guard let todayRecord = findTodayRecord(in: cycle) else {
            return .resting
        }
        
        let todayStatus = todayRecord.status.adjustedForDate(
            todayRecord.scheduledDateTime,
            calendar: timeProvider.calendar
        )
        
        // rest 상태 체크
        if case .rest = todayStatus {
            return .resting
        }
        
        // 복용 완료 상태
        if todayStatus == .todayTaken ||
            todayStatus == .todayTakenDelayed ||
            todayStatus == .takenDouble {
            return .completed
        }
        
        // todayNotTaken 상태일 때 연속 미복용 일수 체크
        if todayStatus == .todayNotTaken || todayStatus == .todayDelayed {
            let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle)
            
            if consecutiveMissed >= 2 {
                return .waiting // 잔디가 기다려요
            } else {
                return .plantingSeed // 잔디를 심어보세요!
            }
        }
        
        return .plantingSeed
    }
    
    // MARK: - Private Methods
    
    private func findTodayRecord(in cycle: PillCycle) -> PillRecord? {
        let now = timeProvider.now
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: now)
        }
    }
    
    private func calculateConsecutiveMissedDays(cycle: PillCycle) -> Int {
        let now = timeProvider.now
        let today = timeProvider.startOfDay(for: now)
        
        var count = 0
        
        for record in cycle.records.reversed() {
            let recordDay = timeProvider.startOfDay(for: record.scheduledDateTime)
            
            guard recordDay < today else { continue }
            
            let status = record.status.adjustedForDate(
                record.scheduledDateTime,
                calendar: timeProvider.calendar
            )
            
            if case .rest = status {
                continue
            }
            
            if case .missed = status {
                count += 1
            } else if status.isTaken {
                break
            }
        }
        
        return count
    }
}
