//
//  DIContainer.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
// MARK: - DI/DIContainer.swift

final class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - DataSources
    
    private lazy var coreDataManager: CoreDataManager = {
        return CoreDataManager.shared
    }()
    
    // MARK: - Repositories
    
    func makePillCycleRepository() -> PillCycleRepositoryProtocol {
        return CoreDataPillCycleRepository(coreDataManager: coreDataManager)
    }
    
    func makeUserSettingsRepository() -> UserSettingsRepositoryProtocol {
        return UserDefaultsUserSettingsRepository()
    }
    
    // MARK: - UseCases
    
    func makeFetchDashboardDataUseCase() -> FetchDashboardDataUseCaseProtocol {
        return FetchDashboardDataUseCase(
            cycleRepository: makePillCycleRepository(),
            settingsRepository: makeUserSettingsRepository()
        )
    }
    
    func makeTakePillUseCase() -> TakePillUseCaseProtocol {
        return TakePillUseCase(cycleRepository: makePillCycleRepository())
    }
    
    func makeUpdatePillStatusUseCase() -> UpdatePillStatusUseCaseProtocol {
        return UpdatePillStatusUseCase(cycleRepository: makePillCycleRepository())
    }
    
    func makeCalculateDashboardMessageUseCase() -> CalculateDashboardMessageUseCaseProtocol {
        return CalculateDashboardMessageUseCase()
    }
    
    // MARK: - ViewModels
    
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(
            fetchDashboardDataUseCase: makeFetchDashboardDataUseCase(),
            takePillUseCase: makeTakePillUseCase(),
            updatePillStatusUseCase: makeUpdatePillStatusUseCase(),
            calculateDashboardMessageUseCase: makeCalculateDashboardMessageUseCase()
        )
    }
}

extension DIContainer {
    
    func makeTimeSettingViewModel() -> TimeSettingViewModel {
        return TimeSettingViewModel(
            settingsRepository: makeUserSettingsRepository()
        )
    }
    
    func makeTimeSettingViewController() -> TimeSettingViewController {
        let viewModel = makeTimeSettingViewModel()
        return TimeSettingViewController(viewModel: viewModel)
    }
}
