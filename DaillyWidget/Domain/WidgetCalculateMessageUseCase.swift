//
//  WidgetCalculateMessageUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import Foundation

// MARK: - WidgetCalculateMessageUseCase 

final class WidgetCalculateMessageUseCase {
    
    private let statusEvaluator: PillStatusEvaluator
    
    init(statusEvaluator: PillStatusEvaluator) {
        self.statusEvaluator = statusEvaluator
    }
    
    func execute(cycle: PillCycle?, for date: Date = Date()) -> WidgetMessageType {
        guard let cycle = cycle else {
            return .empty
        }
        
        let decision = statusEvaluator.evaluate(
            cycle: cycle,
            items: cycle.records,
            at: date
        )
        return decision.toWidgetMessageType()
    }
}
