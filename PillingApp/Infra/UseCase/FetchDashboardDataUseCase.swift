//
//  FetchDashboardDataUseCase.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/21/25.
//

import RxSwift

protocol FetchDashboardDataUseCaseProtocol {
    func execute() -> Observable<(cycle: Cycle?, settings: UserSettings)>
}
//MARK: - 현재 사이클 + 사용자 설정을 받음 유스케이스. UserDefaults에 저장된 currentCycleID가 있으면 해당 사이클 정보를 받아옴.
final class FetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol {
    private let cycleRepository: CycleRepositoryProtocol
    private let settingsRepository: UserDefaultsProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    
    init(
        cycleRepository: CycleRepositoryProtocol,
        settingsRepository: UserDefaultsProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        print("순서:\(#fileID)")
        
        self.cycleRepository = cycleRepository
        self.settingsRepository = settingsRepository
        self.userDefaultsManager = userDefaultsManager
    }
    
    func execute() -> Observable<(cycle: Cycle?, settings: UserSettings)> {
        let cycleObservable: Observable<Cycle?>
        
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
