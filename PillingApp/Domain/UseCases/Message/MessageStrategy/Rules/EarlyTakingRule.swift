import Foundation

final class EarlyTakingRule: MessageRule {
    let priority = 50

    func shouldEvaluate(context: MessageContext) -> Bool {
        let isTooEarly = (context.todayStatus?.isTaken == true )&&(context.yesterdayIsMissed == false)&&(context.todayStatus?.medicalTiming == .tooEarly)
        print("      [EarlyTakingRule] medicalTiming=\(context.todayStatus?.medicalTiming.rawValue ?? "nil"), tooEarly=\(isTooEarly)")
        return isTooEarly
    }

    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus else { return nil }

        if todayStatus.isTaken {
            print("      [EarlyTakingRule] 너무 일찍 복용함 → .takenTooEarly")
            return .takenTooEarly
        } else {
            print("      [EarlyTakingRule] 아직 복용 전 → .plantingSeed")
            return .plantingSeed
        }
    }
}
