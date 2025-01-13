import Foundation

protocol TimeProvider {
    var now: Date { get }
    var calendar: Calendar { get }
    var timeZone: TimeZone { get }
    
    func startOfDay(for date: Date) -> Date
    func isDateInToday(_ date: Date) -> Bool
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool
    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date?
    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents
}

final class SystemTimeProvider: TimeProvider {
    var now: Date {
        return Date()
    }
    
    var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal
    }
    
    var timeZone: TimeZone { TimeZone.current }
    
    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    func isDateInToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
    
    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        calendar.date(byAdding: component, value: value, to: date)
    }
    
    func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        calendar.dateComponents(components, from: date)
    }
}
