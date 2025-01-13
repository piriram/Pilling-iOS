import Foundation

// MARK: - DateEnvironment
struct DateEnvironment {
    let calendar: Calendar
    let now: Date
    
    static var `default`: DateEnvironment {
        .init(calendar: .current, now: Date())
    }
}
