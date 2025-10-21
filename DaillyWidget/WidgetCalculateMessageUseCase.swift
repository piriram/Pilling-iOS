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
        
        let todayStatus = calculateStatus(for: todayRecord, at: date)
        
        if case .rest = todayStatus {
            return .resting
        }
        
        // 오늘 관련 상태일 때만 복잡한 로직 적용
        if isTodayRelatedStatus(todayStatus) {
            let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle, upTo: date)
            
            // 2일 이상 연속 미복용 + 오늘 복용 완료
            if consecutiveMissed >= 2,
               (todayStatus == .todayTaken ||
                todayStatus == .todayTakenDelayed ||
                todayStatus == .todayTakenTooEarly) {
                return .success
            }
            
            // 2일 이상 연속 미복용 + 오늘 미복용
            if consecutiveMissed >= 2 {
                return .waiting
            }
            
            // 어제 미복용 상황 체크
            if let yesterdayRecord = findYesterdayRecord(in: cycle, from: date) {
                let yesterdayStatus = yesterdayRecord.status.adjustedForDate(
                    yesterdayRecord.scheduledDateTime,
                    calendar: timeProvider.calendar
                )
                
                if case .missed = yesterdayStatus,
                   consecutiveMissed == 1,
                   (todayStatus == .todayTaken ||
                    todayStatus == .todayTakenDelayed ||
                    todayStatus == .todayTakenTooEarly) {
                    return .pilledTwo
                }
                
                if case .missed = yesterdayStatus,
                   case .takenDouble = todayStatus {
                    // 오늘 2알 복용으로 보정 완료
                } else if case .missed = yesterdayStatus,
                          (todayStatus == .todayTaken ||
                           todayStatus == .todayDelayed ||
                           todayStatus == .todayDelayedCritical ||
                           todayStatus == .takenTooEarly) {
                    return .pilledTwo
                } else if case .missed = yesterdayStatus {
                    return .pilledTwo
                }
            }
        }
        
        // 개별 상태에 따른 메시지
        switch todayStatus {
        case .todayTaken:
            return .success
            
        case .todayTakenDelayed:
            return .success
            
        case .todayTakenTooEarly:
            return .success
            
        case .todayDelayed:
            return .groomy
            
        case .todayDelayedCritical:
            return .fire
            
        case .takenDouble:
            return .success
            
        case .todayNotTaken:
            return .plantingSeed
            
        case .taken, .takenDelayed, .missed, .scheduled, .takenTooEarly:
            return .resting
            
        case .rest:
            return .resting
        }
    }
    
    // MARK: - Private Methods
    
    private func findRecord(in cycle: PillCycle, for date: Date) -> PillRecord? {
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: date)
        }
    }
    
    private func findYesterdayRecord(in cycle: PillCycle, from date: Date) -> PillRecord? {
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: yesterday)
        }
    }
    
    private func calculateStatus(for record: PillRecord, at date: Date) -> PillStatus {
        let calendar = timeProvider.calendar
        
        if record.status.isTaken {
            return record.status.adjustedForDate(record.scheduledDateTime, calendar: calendar)
        }
        
        let scheduledTime = record.scheduledDateTime
        let timeDifference = date.timeIntervalSince(scheduledTime)
        
        let twoHours: TimeInterval = 2 * 60 * 60
        let fourHours: TimeInterval = 4 * 60 * 60
        
        if timeDifference < twoHours {
            return .todayNotTaken
        } else if timeDifference < fourHours {
            return .todayDelayed
        } else {
            return .todayDelayedCritical
        }
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
