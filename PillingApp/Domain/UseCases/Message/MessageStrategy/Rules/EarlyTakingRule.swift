import Foundation

final class EarlyTakingRule: MessageRule {
    let priority = 50

    func shouldEvaluate(context: MessageContext) -> Bool {
        let isTooEarly = (context.todayStatus?.isTaken == true )&&(context.yesterdayIsMissed == false)&&(context.todayStatus?.medicalTiming == .tooEarly)
        return isTooEarly
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus else { return nil }

        if todayStatus.isTaken {
            return .takenTooEarly
        } else {
            return .plantingSeed
        }
    }
}
