//
//  CalculateDashboardMessageUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation

protocol CalculateDashboardMessageUseCaseProtocol {
    func execute(cycle: Cycle?) -> DashboardMessage
}

// MARK: - Cycle를 MessageResult로 계산

final class CalculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol {
    
    private let calculateMessageUseCase: CalculateMessageUseCase
    private let timeProvider: TimeProvider
    
    init(timeProvider: TimeProvider) {
        print("순서:\(#fileID)")
        
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
//protocol FetchDashboardDataUseCaseProtocol {
//    func execute() -> Observable<(cycle: Cycle?, settings: UserSettings)>
//}
//
//final class FetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol {
//    private let cycleRepository: CycleRepositoryProtocol
//    private let settingsRepository: UserDefaultsProtocol
//    
//    init(
//        cycleRepository: CycleRepositoryProtocol,
//        settingsRepository: UserDefaultsProtocol
//    ) {
//        self.cycleRepository = cycleRepository
//        self.settingsRepository = settingsRepository
//    }
//    
//    func execute() -> Observable<(cycle: Cycle?, settings: UserSettings)> {
//        // 1. 사이클 로드 (폴백 포함)
//        let cycleObservable = loadCycleWithFallback()
//        
//        // 2. 설정 로드 (기본값 대체)
//        let settingsObservable = settingsRepository.fetchSettings()
//            .catch { error -> Observable<UserSettings> in
//                print("⚠️ 설정 로드 실패, 기본값 사용: \(error)")
//                return .just(UserSettings.default)
//            }
//        
//        // 3. 결합
//        return Observable.zip(
//            cycleObservable,
//            settingsObservable
//        )
//        .map { (cycle: $0, settings: $1) }
//    }
//    
//    private func loadCycleWithFallback() -> Observable<Cycle?> {
//        guard let currentCycleID = cycleRepository.getCurrentCycleID() else {
//            print("📌 currentCycleID 없음, 기본 로직으로 사이클 로드")
//            return cycleRepository.fetchCurrentCycle()
//        }
//        
//        print("📌 저장된 currentCycleID로 사이클 로드: \(currentCycleID)")
//        
//        return cycleRepository.fetchCycle(by: currentCycleID)
//            .flatMap { [weak self] cycle -> Observable<Cycle?> in
//                guard let self = self else { return .just(nil) }
//                
//                if cycle == nil {
//                    print("⚠️ 저장된 사이클 없음, 기본 로직으로 폴백")
//                    return self.cycleRepository.fetchCurrentCycle()
//                }
//                
//                return .just(cycle)
//            }
//    }
//}
