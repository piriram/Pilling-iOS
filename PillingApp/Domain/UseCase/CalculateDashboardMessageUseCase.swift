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
    func execute(cycle: PillCycle?) -> DashboardMessage
}

// MARK: - CalculateDashboardMessageUseCase

final class CalculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol {
    
    private let calculateMessageUseCase: CalculateMessageUseCase
    private let timeProvider: TimeProvider
    
    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
        self.calculateMessageUseCase = CalculateMessageUseCase(timeProvider: timeProvider)
    }
    
    func execute(cycle: PillCycle?) -> DashboardMessage {
        // 공통 UseCase 사용
        let result = calculateMessageUseCase.execute(cycle: cycle, for: timeProvider.now)
        
        // MessageResult를 DashboardMessage로 변환
        return result.toDashboardMessage()
    }
}

// MARK: - MessageResult + DashboardMessage

extension MessageResult {
    
    func toDashboardMessage() -> DashboardMessage {
        let characterImage = DashboardUI.CharacterImage(rawValue: characterImageName) ?? .rest
        let icon = DashboardUI.MessageIconImage(rawValue: iconImageName) ?? .rest
        
        return DashboardMessage(
            text: text,
            imageName: characterImage,
            icon: icon
        )
    }
}
