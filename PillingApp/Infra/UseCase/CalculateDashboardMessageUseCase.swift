import Foundation

protocol CalculateDashboardMessageUseCaseProtocol {
    func execute(cycle: Cycle?) -> DashboardMessage
}

// MARK: - Cycle를 MessageResult로 계산

final class CalculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol {
    
    private let calculateMessageUseCase: CalculateMessageUseCase
    private let timeProvider: TimeProvider
    
    init(timeProvider: TimeProvider) {
        
        self.timeProvider = timeProvider
        self.calculateMessageUseCase = CalculateMessageUseCase(timeProvider: timeProvider)
    }
    
    func execute(cycle: Cycle?) -> DashboardMessage {
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
