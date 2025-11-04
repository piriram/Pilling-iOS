//
//  FetchDashboardDataUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/21/25.
//

import RxSwift
// MARK: - Domain/UseCases/FetchDashboardDataUseCase.swift

protocol FetchDashboardDataUseCaseProtocol {
    func execute() -> Observable<(cycle: PillCycle?, settings: UserSettings)>
}
final class FetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol {
    private let cycleRepository: PillCycleRepositoryProtocol
    private let settingsRepository: UserSettingsRepositoryProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    init(
        cycleRepository: PillCycleRepositoryProtocol,
        settingsRepository: UserSettingsRepositoryProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        self.cycleRepository = cycleRepository
        self.settingsRepository = settingsRepository
        self.userDefaultsManager = userDefaultsManager
    }
    
    func execute() -> Observable<(cycle: PillCycle?, settings: UserSettings)> {
        let cycleObservable: Observable<PillCycle?>
        
        if let currentCycleID = userDefaultsManager.loadCurrentCycleID() {
            print("📌 저장된 currentCycleID로 사이클 로드: \(currentCycleID)")
            cycleObservable = cycleRepository.fetchCycle(by: currentCycleID)
        } else {
            print("📌 currentCycleID 없음, 기본 로직으로 사이클 로드")
            cycleObservable = cycleRepository.fetchCurrentCycle()
        }
        
        return Observable.zip(
            cycleObservable,
            settingsRepository.fetchSettings()
        )
        .map { (cycle: $0, settings: $1) }
    }
}
