import Foundation

/// 본앱과 위젯에서 공통으로 사용하는 메시지 계산
final class CalculateMessageUseCase {
    
    private let timeProvider: TimeProvider
    
    init(timeProvider: TimeProvider = SystemTimeProvider()) {
        self.timeProvider = timeProvider
    }
    
    // MARK: - Execute
    
    func execute(cycle: Cycle?, for date: Date = Date()) -> MessageResult {
        guard let cycle = cycle else {
            return MessageType.empty.toResult()
        }
        
        // 복용 시작일 이전 체크
        if date < cycle.startDate {
            return makeBeforeStartMessage(startDate: cycle.startDate, currentDate: date)
        }
        
        guard let todayRecord = findRelevantRecord(in: cycle, for: date) else {
            // 오늘 레코드가 없는데 어제 레코드가 12시간 초과한 경우 체크
            if let yesterdayRecord = findYesterdayRecord(in: cycle, from: date) {
                let twelveHours: TimeInterval = 12 * 60 * 60
                let timeSinceScheduled = date.timeIntervalSince(yesterdayRecord.scheduledDateTime)
                
                if timeSinceScheduled >= twelveHours,
                   !yesterdayRecord.status.isTaken,
                   yesterdayRecord.status != .rest {
                    return MessageType.pilledTwo.toResult()
                }
            }
            
            return MessageType.resting.toResult()
        }
        
        let todayStatus = calculateStatus(for: todayRecord, at: date)
        
        if case .rest = todayStatus {
            return MessageType.resting.toResult()
        }
        
        // 오늘 관련 상태일 때만 복잡한 로직 적용
        if isTodayRelatedStatus(todayStatus) {
            let consecutiveMissed = calculateConsecutiveMissedDays(cycle: cycle, upTo: date)
            
            // 2일 이상 연속 미복용 + 오늘 복용 완료
            if consecutiveMissed >= 2,
               (todayStatus == .todayTaken ||
                todayStatus == .todayTakenDelayed ||
                todayStatus == .todayTakenTooEarly) {
                return MessageType.success.toResult()
            }
            
            // 2일 이상 연속 미복용 + 오늘 미복용
            if consecutiveMissed >= 2 {
                return MessageType.waiting.toResult()
            }
            
            // 어제 미복용 상황 체크
            if let yesterdayRecord = findYesterdayRecord(in: cycle, from: date) {
                let yesterdayStatus = yesterdayRecord.status.adjustedForDate(
                    yesterdayRecord.scheduledDateTime,
                    calendar: timeProvider.calendar
                )
                
                // 어제 missed && consecutiveMissed == 1 && 오늘 복용 완료
                if case .missed = yesterdayStatus,
                   consecutiveMissed == 1,
                   (todayStatus == .todayTaken ||
                    todayStatus == .todayTakenDelayed ||
                    todayStatus == .todayTakenTooEarly) {
                    return MessageType.takingBeforeTwo.toResult()
                }
                
                // 어제 missed && 오늘 takenDouble (2알 복용으로 보정 완료)
                if case .missed = yesterdayStatus,
                   case .takenDouble = todayStatus {
                    return MessageType.takingBefore.toResult()
                }
                // 어제 missed && 오늘 todayTaken/takenTooEarly (1알만 복용)
                else if case .missed = yesterdayStatus,
                        (todayStatus == .todayTaken ||
                         todayStatus == .takenTooEarly) {
                    return MessageType.warning.toResult()
                }
                // 어제 missed (아직 오늘 복용 안 함)
                else if case .missed = yesterdayStatus {
                    return MessageType.pilledTwo.toResult()
                }
            }
        }
        
        // 개별 상태에 따른 메시지
        switch todayStatus {
        case .todayTaken:
            return MessageType.todayAfter.toResult()
            
        case .todayTakenDelayed:
            return MessageType.takenDelayedOk.toResult()
            
        case .todayTakenTooEarly:
            return MessageType.takenTooEarly.toResult()
            
        case .todayDelayed:
            return MessageType.groomy.toResult()
            
        case .todayDelayedCritical:
            return MessageType.fire.toResult()
            
        case .takenDouble:
            return MessageType.takenDoubleComplete.toResult()
            
        case .todayNotTaken:
            return MessageType.plantingSeed.toResult()
            
        case .taken, .takenDelayed, .missed, .scheduled, .takenTooEarly:
            return MessageType.resting.toResult()
            
        case .rest:
            return MessageType.resting.toResult()
        }
    }
    
    // MARK: - Private Methods
    
    private func makeBeforeStartMessage(startDate: Date, currentDate: Date) -> MessageResult {
        let calendar = timeProvider.calendar
        let components = calendar.dateComponents([.day], from: currentDate, to: startDate)
        
        guard let daysUntilStart = components.day else {
            return MessageType.beforeStart(daysUntilStart: 0).toResult()
        }
        
        return MessageType.beforeStart(daysUntilStart: daysUntilStart).toResult()
    }
    
    private func findRelevantRecord(in cycle: Cycle, for date: Date) -> DayRecord? {
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
    
    private func findYesterdayRecord(in cycle: Cycle, from date: Date) -> DayRecord? {
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: yesterday)
        }
    }
    
    private func calculateStatus(for record: DayRecord, at date: Date) -> PillStatus {
        let calendar = timeProvider.calendar
        
        // takenDouble은 그대로 유지
        if record.status == .takenDouble {
            return .takenDouble
        }
        
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
    
    private func calculateConsecutiveMissedDays(cycle: Cycle, upTo targetDate: Date) -> Int {
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
