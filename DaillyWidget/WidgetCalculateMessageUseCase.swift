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
    
    func execute(cycle: PillCycle?, for date: Date = Date()) -> WidgetMessageType {
        guard let cycle = cycle else {
            return .empty
        }
        
        guard let todayRecord = findRecord(in: cycle, for: date) else {
            return .resting
        }
        
        // 현재 시간 기준으로 상태 계산
        let todayStatus = calculateStatus(for: todayRecord, at: date)
        
        // rest 상태 체크
        if case .rest = todayStatus {
            return .resting
        }
        
        // 연속 미복용 일수 계산
        let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle, upTo: date)
        
        // 2일 이상 안 먹었고, 오늘 복용한 경우 - 격려 메시지
        if consecutiveMissed >= 2,
           (todayStatus == .todayTaken || todayStatus == .todayTakenDelayed || todayStatus == .todayTakenTooEarly) {
            return .completed
        }
        
        // todayDelayed: 2시간 초과 - 무조건 경고! ⚠️
        if todayStatus == .todayDelayed {
            return .waiting
        }
        
        // 2일 이상 안 먹었고, 오늘도 아직 안 먹음 - 경고!
        if consecutiveMissed >= 2 {
            return .waiting
        }
        
        // 복용 완료 상태
        if todayStatus == .todayTaken ||
            todayStatus == .todayTakenDelayed ||
            todayStatus == .takenDouble {
            return .completed
        }
        
        // 오늘 아직 안 먹음 (시간 내)
        if todayStatus == .todayNotTaken {
            return .plantingSeed
        }
        
        return .plantingSeed
    }
    
    // MARK: - Private Methods
    
    private func findRecord(in cycle: PillCycle, for date: Date) -> PillRecord? {
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: date)
        }
    }
    
    /// 특정 시간에 해당하는 상태 계산
    private func calculateStatus(for record: PillRecord, at date: Date) -> PillStatus {
        let calendar = timeProvider.calendar
        
        // 이미 복용한 경우
        if record.status.isTaken {
            return record.status.adjustedForDate(record.scheduledDateTime, calendar: calendar)
        }
        
        // 복용 예정 시간과 현재 시간 비교
        let scheduledTime = record.scheduledDateTime
        let timeDifference = date.timeIntervalSince(scheduledTime)
        
        // 2시간 = 7200초
        let twoHours: TimeInterval = 2 * 60 * 60
        
        // 아직 복용 시간 전이거나 2시간 이내
        if timeDifference < twoHours {
            return .todayNotTaken
        } else {
            // 2시간 초과
            return .todayDelayed
        }
    }
    
    private func calculateConsecutiveMissedDays(cycle: PillCycle, upTo targetDate: Date) -> Int {
        let today = timeProvider.startOfDay(for: targetDate)
        
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
