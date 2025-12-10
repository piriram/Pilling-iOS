import Foundation

final class MessageRuleEngine {
    private let rules: [MessageRule]

    init(rules: [MessageRule]) {
        self.rules = rules.sorted { $0.priority < $1.priority }
    }

    func evaluate(context: MessageContext) -> MessageType {
        for rule in rules {
            let ruleName = String(describing: type(of: rule))
            let shouldEval = rule.shouldEvaluate(context: context)

            if shouldEval {
                if let result = rule.evaluate(context: context) {
                    return result
                }
            }
        }

        return .empty
    }
}
