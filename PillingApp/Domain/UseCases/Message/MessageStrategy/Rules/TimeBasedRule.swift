import Foundation

final class TimeBasedRule: MessageRule {
    let priority = 500

    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let todayStatus = context.todayStatus else { return false }
        return !todayStatus.isTaken &&
               todayStatus.medicalTiming != .tooEarly &&
               todayStatus.medicalTiming != .upcoming
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let status = context.todayStatus else { return nil }

        if status.isTaken {
            switch status.baseStatus {
            case .taken:
                return .todayAfter
            case .takenDelayed:
                return .takenDelayedOk
            case .takenTooEarly:
                return .takenTooEarly
            case .takenDouble:
                return .takenDoubleComplete
            default:
                return .todayAfter
            }
        }

        switch status.medicalTiming {
        case .onTime:
            return .plantingSeed
        case .slightDelay:
            return .groomy
        case .moderate:
            return .fire
        case .recent:
            return .waiting
        case .missed:
            return .waiting
        default:
            return .plantingSeed
        }
    }
}
