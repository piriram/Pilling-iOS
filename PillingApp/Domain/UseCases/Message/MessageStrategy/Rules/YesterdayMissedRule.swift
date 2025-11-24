import Foundation

final class YesterdayMissedRule: MessageRule {
    let priority = 300

    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let yesterday = context.yesterdayStatus else { return false }
        return yesterday.baseStatus == .missed && context.consecutiveMissedDays == 1
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus else { return nil }

        if todayStatus.baseStatus == .takenDouble {
            return .takingBefore
        }

        if todayStatus.isTaken && todayStatus.baseStatus != .takenDouble {
            return .warning
        }

        if !todayStatus.isTaken {
            return .pilledTwo
        }

        return nil
    }
}
