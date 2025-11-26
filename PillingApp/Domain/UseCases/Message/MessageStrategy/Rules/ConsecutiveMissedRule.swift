import Foundation

final class ConsecutiveMissedRule: MessageRule {
    let priority = 100

    func shouldEvaluate(context: MessageContext) -> Bool {
        let hasMissed = context.consecutiveMissedDays > 0
        print("      [ConsecutiveMissedRule] 연속미복용일수=\(context.consecutiveMissedDays), 평가대상=\(hasMissed)")
        return hasMissed
    }

    func evaluate(context: MessageContext) -> MessageType? {
        let days = context.consecutiveMissedDays

        if days >= 3 {
            print("🌱      [ConsecutiveMissedRule] 3일 이상 미복용")
            return .waiting
        }
        if days >= 2 {
            print("🌱      [ConsecutiveMissedRule] 2일 이상 미복용")
            return .fire
        }

        if days >= 1 {
            if context.todayIsTaken {
                print("🌱      [ConsecutiveMissedRule] pilledTwo")
                return .pilledTwo
            } else {
                print("🌱      [ConsecutiveMissedRule] groomy")
                return .groomy
            }
        }

        print("🌱      [ConsecutiveMissedRule] 1일 미만 → nil")
        return nil
    }
}
