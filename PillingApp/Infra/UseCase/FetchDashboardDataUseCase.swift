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
        self.cycleRepository = cycleRepository
        self.settingsRepository = settingsRepository
        self.userDefaultsManager = userDefaultsManager
    }
    
    func execute() -> Observable<(cycle: Cycle?, settings: UserSettings)> {
        let cycleObservable = loadCycleWithFallback()

        let settingsObservable = settingsRepository.fetchSettings()
            .catch { error -> Observable<UserSettings> in
                return .just(UserSettings.default)
            }

        return Observable.zip(
            cycleObservable,
            settingsObservable
        )
        .map { (cycle: $0, settings: $1) }
    }
    
    private func loadCycleWithFallback() -> Observable<Cycle?> {
        guard let currentCycleID = userDefaultsManager.loadCurrentCycleID() else {
            return cycleRepository.fetchCurrentCycle()
        }

        return cycleRepository.fetchCycle(by: currentCycleID)
            .flatMap { [weak self] cycle -> Observable<Cycle?> in
                guard let self = self else { return .just(nil) }

                if cycle == nil {
                    return self.cycleRepository.fetchCurrentCycle()
                }

                return .just(cycle)
            }
    }
}
