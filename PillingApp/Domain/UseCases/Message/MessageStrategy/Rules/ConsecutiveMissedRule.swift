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

        if days >= 7 {
            print("      [ConsecutiveMissedRule] 7일 이상 미복용 → .waiting")
            return .waiting
        }

        if days >= 2 {
            if context.todayIsTaken {
                print("      [ConsecutiveMissedRule] 2일 이상 미복용했지만 오늘 복용 → .success")
                return .success
            } else {
                print("      [ConsecutiveMissedRule] 2일 이상 미복용 → .waiting")
                return .waiting
            }
        }

        print("      [ConsecutiveMissedRule] 2일 미만 → nil")
        return nil
    }
}
