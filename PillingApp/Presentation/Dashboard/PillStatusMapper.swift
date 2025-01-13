import Foundation

enum StatusButtonTag: Int {
    case notTaken = 0
    case taken = 1
    case takenDouble = 2
    case none = -1
}

struct PillStatusMapper {
    
    static func mapStatusToButtonTag(_ status: PillStatus) -> StatusButtonTag {
        switch status {
        case .missed, .scheduled, .todayNotTaken, .todayDelayed, .todayDelayedCritical:
            return .notTaken
        case .taken, .takenDelayed, .todayTaken, .todayTakenDelayed, .todayTakenTooEarly, .takenTooEarly:
            return .taken
        case .takenDouble:
            return .takenDouble
        case .rest:
            return .none
        }
    }
    
    static func mapButtonTagToStatus(_ tag: StatusButtonTag, currentDate: Date) -> PillStatus? {
        switch tag {
        case .notTaken:
            return .todayNotTaken
        case .taken:
            return .todayTaken
        case .takenDouble:
            return .takenDouble
        case .none:
            return nil
        }
    }
}
