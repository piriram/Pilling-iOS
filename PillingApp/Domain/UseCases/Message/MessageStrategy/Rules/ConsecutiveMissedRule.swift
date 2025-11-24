import Foundation

final class ConsecutiveMissedRule: MessageRule {
    let priority = 100

    func shouldEvaluate(context: MessageContext) -> Bool {
        context.consecutiveMissedDays > 0
    }

    func evaluate(context: MessageContext) -> MessageType? {
        let days = context.consecutiveMissedDays

        if days >= 7 {
            return .waiting
        }

        if days >= 2 {
            if context.todayIsTaken {
                return .success
            } else {
                return .waiting
            }
        }

        return nil
    }
}
