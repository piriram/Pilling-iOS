//
//  CalculateDashboardMessageUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift
import UIKit

// MARK: - CalculateDashboardMessageUseCaseProtocol

protocol CalculateDashboardMessageUseCaseProtocol {
    func execute(cycle: PillCycle?, items: [DayItem]) -> DashboardMessage
}

// MARK: - CalculateDashboardMessageUseCase

final class CalculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol {
    
    private let statusEvaluator: PillStatusEvaluator
    private let timeProvider: TimeProvider
    
    init(
        statusEvaluator: PillStatusEvaluator,
        timeProvider: TimeProvider
    ) {
        self.statusEvaluator = statusEvaluator
        self.timeProvider = timeProvider
    }
    
    func execute(cycle: PillCycle?, items: [DayItem]) -> DashboardMessage {
        let decision = statusEvaluator.evaluate(
            cycle: cycle,
            items: items,
            at: timeProvider.now
        )
        return decision.toDashboardMessage()
    }
}
