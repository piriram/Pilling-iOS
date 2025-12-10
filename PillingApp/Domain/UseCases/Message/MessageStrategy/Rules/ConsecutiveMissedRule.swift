import Foundation

final class ConsecutiveMissedRule: MessageRule {
    let priority = 100

    func shouldEvaluate(context: MessageContext) -> Bool {
        let hasMissed = context.consecutiveMissedDays > 0
        return hasMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        let days = context.consecutiveMissedDays

        if days >= 3 {
            return .waiting
        }
        if days >= 2 {
            return .fire
        }

        if days >= 1 {
            if context.todayIsTaken {
                return .pilledTwo
            } else {
                return .groomy
            }
        }

        return nil
    }
}
