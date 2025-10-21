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
        
        guard let todayRecord = findRelevantRecord(in: cycle, for: date) else {
            // 오늘 레코드가 없는데 어제 레코드가 12시간 초과한 경우 체크
            if let yesterdayRecord = findYesterdayRecord(in: cycle, from: date) {
                let twelveHours: TimeInterval = 12 * 60 * 60
                let timeSinceScheduled = date.timeIntervalSince(yesterdayRecord.scheduledDateTime)
                
                if timeSinceScheduled >= twelveHours,
                   !yesterdayRecord.status.isTaken,
                   yesterdayRecord.status != .rest {
                    return .pilledTwo
                }
            }
            
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
            
        case .missed:
            return .pilledTwo
            
        case .taken, .takenDelayed, .scheduled, .takenTooEarly:
            return .resting
            
        case .rest:
            return .resting
        }
    }
    
    // MARK: - Private Methods
    
    private func findRelevantRecord(in cycle: PillCycle, for date: Date) -> PillRecord? {
        // 1. 오늘 날짜의 레코드 찾기
        if let todayRecord = cycle.records.first(where: { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: date)
        }) {
            return todayRecord
        }
        
        // 2. 어제 레코드가 12시간 윈도우 내인지 확인
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: date),
              let yesterdayRecord = cycle.records.first(where: { record in
                  timeProvider.isDate(record.scheduledDateTime, inSameDayAs: yesterday)
              }) else {
            return nil
        }
        
        // 어제 복용 예정 시간으로부터 12시간 이내인지 확인
        let twelveHours: TimeInterval = 12 * 60 * 60
        let timeSinceScheduled = date.timeIntervalSince(yesterdayRecord.scheduledDateTime)
        
        if timeSinceScheduled < twelveHours,
           !yesterdayRecord.status.isTaken,
           yesterdayRecord.status != .rest {
            return yesterdayRecord
        }
        
        return nil
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
        let twelveHours: TimeInterval = 12 * 60 * 60
        
        if timeDifference < twoHours {
            return .todayNotTaken
        } else if timeDifference < fourHours {
            return .todayDelayed
        } else if timeDifference < twelveHours {
            return .todayDelayedCritical
        } else {
            return .missed
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
            
            // 12시간 윈도우 체크
            let twelveHours: TimeInterval = 12 * 60 * 60
            let timeSinceScheduled = targetDate.timeIntervalSince(record.scheduledDateTime)
            
            if timeSinceScheduled >= twelveHours, !record.status.isTaken {
                count += 1
            } else if status.isTaken {
                break
            }
        }
        
        return count
    }
}
