import Foundation

final class TimeBasedRule: MessageRule {
    let priority = 500

    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let todayStatus = context.todayStatus else {
            print("      [TimeBasedRule] 오늘 상태 없음")
            return false
        }

        // TimeBasedRule은 기본 폴백 룰이므로, tooEarly와 upcoming만 제외
        let notEarly = todayStatus.medicalTiming != .tooEarly
        let notUpcoming = todayStatus.medicalTiming != .upcoming

        print("      [TimeBasedRule] 복용=\(todayStatus.isTaken ? "함" : "안함"), medicalTiming=\(todayStatus.medicalTiming.rawValue)")

        return notEarly && notUpcoming
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let status = context.todayStatus else { return nil }

        if status.isTaken {
            let message: MessageType
            switch status.baseStatus {
            case .taken:
                message = .todayAfter
            case .takenDelayed:
                message = .takenDelayedOk
            case .takenTooEarly:
                message = .takenTooEarly
            case .takenDouble:
                message = .takenDoubleComplete
            default:
                message = .todayAfter
            }
            print("      [TimeBasedRule] 복용함 → \(message)")
            return message
        }

        let message: MessageType
        switch status.medicalTiming {
        case .onTime:
            message = .plantingSeed
        case .slightDelay:
            message = .groomy
        case .moderate:
            message = .fire
        case .recent:
            message = .waiting
        case .missed:
            message = .waiting
        default:
            message = .plantingSeed
        }
        print("      [TimeBasedRule] 시간기반 → \(message)")
        return message
    }
}
