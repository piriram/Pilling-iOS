//
//  DashboardMessage.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import RxSwift

// MARK: - Domain/Entities/DashboardMessage.swift

struct DashboardMessage {
    let text: String
    let imageName: DashboardUI.CharacterImage
    let icon: DashboardUI.MessageIconImage
}

// MARK: - Domain/UseCases/FetchDashboardDataUseCase.swift

protocol FetchDashboardDataUseCaseProtocol {
    func execute() -> Observable<(cycle: PillCycle?, settings: UserSettings)>
}
final class FetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol {
    private let cycleRepository: PillCycleRepositoryProtocol
    private let settingsRepository: UserSettingsRepositoryProtocol
    
    init(
        cycleRepository: PillCycleRepositoryProtocol,
        settingsRepository: UserSettingsRepositoryProtocol
    ) {
        self.cycleRepository = cycleRepository
        self.settingsRepository = settingsRepository
    }
    
    func execute() -> Observable<(cycle: PillCycle?, settings: UserSettings)> {
        return Observable.zip(
            cycleRepository.fetchCurrentCycle(),
            settingsRepository.fetchSettings()
        )
        .map { (cycle: $0, settings: $1) }
    }
}

