import Foundation

final class MessageRuleEngine {
    private let rules: [MessageRule]

    init(rules: [MessageRule]) {
        self.rules = rules.sorted { $0.priority < $1.priority }
    }

    func evaluate(context: MessageContext) -> MessageType {
        print("🔍 [MessageRuleEngine] 메시지 룰 평가 시작")
        print("   📅 오늘: \(context.todayStatus?.baseStatus.rawValue ?? "nil")")
        print("   📅 어제: \(context.yesterdayStatus?.baseStatus.rawValue ?? "nil")")
        print("   📊 연속미복용: \(context.consecutiveMissedDays)일")
        print("   ⏰ 현재 시각: \(context.currentDate)")

        for rule in rules {
            let ruleName = String(describing: type(of: rule))
            let shouldEval = rule.shouldEvaluate(context: context)

            print("   🎯 [\(ruleName)] priority=\(rule.priority), shouldEvaluate=\(shouldEval)")

            if shouldEval {
                if let result = rule.evaluate(context: context) {
                    print("   ✅ [\(ruleName)] 매칭됨 → \(result)")
                    return result
                } else {
                    print("   ⚠️  [\(ruleName)] shouldEvaluate=true 였지만 evaluate=nil")
                }
            }
        }

        print("   ❌ 모든 룰 미매칭 → 기본 메시지 (.plantingSeed)")
        return .plantingSeed
    }
}
