import Foundation

// MARK: - PillCycle

struct Cycle {
    let id: UUID
    let cycleNumber: Int
    let startDate: Date
    let activeDays: Int
    let breakDays: Int
    var scheduledTime: String
    var records: [DayRecord]
    let createdAt: Date
    
    var totalDays: Int { activeDays + breakDays }
    
    func isActiveDay(forDay day: Int) -> Bool {
        return day >= 1 && day <= activeDays
    }
    
    func isBreakDay(forDay day: Int) -> Bool {
        return day > activeDays && day <= totalDays
    }

    // 현재 날짜가 위약 기간인지 확인
    func isCurrentlyInBreakPeriod() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let daysSinceStart = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: now)).day ?? 0
        let currentDay = daysSinceStart + 1
        return isBreakDay(forDay: currentDay)
    }

    // 사이클이 완료되었는지 확인
    func isCycleCompleted() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let daysSinceStart = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: now)).day ?? 0
        let currentDay = daysSinceStart + 1
        return currentDay > totalDays
    }

    var recordsByDate: [Date: DayRecord] {
           let calendar = Calendar.current
           return Dictionary(
               uniqueKeysWithValues: records.map {
                   (calendar.startOfDay(for: $0.scheduledDateTime), $0)
               }
           )
       }
}
