//
//  DIContainer.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation

final class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - DataSources
    
    private lazy var coreDataManager: CoreDataManager = {
        return CoreDataManager.shared
    }()
    
    // MARK: - Time Provider (추가)
    
    lazy var timeProvider: TimeProvider = {
        SystemTimeProvider()
    }()
    
    // MARK: - Managers
    
    func makeNotificationManager() -> NotificationManagerProtocol {
        return LocalNotificationManager()
    }
    
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol {
        return UserDefaultsManager()
    }
    
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
        return TakePillUseCase(
            cycleRepository: makePillCycleRepository(),
            timeProvider: timeProvider  // 추가
        )
    }
    
    func makeUpdatePillStatusUseCase() -> UpdatePillStatusUseCaseProtocol {
        return UpdatePillStatusUseCase(
            cycleRepository: makePillCycleRepository(),
            timeProvider: timeProvider  // 추가
        )
    }
    
    func makeCalculateDashboardMessageUseCase() -> CalculateDashboardMessageUseCaseProtocol {
        return CalculateDashboardMessageUseCase(
            timeProvider: timeProvider  // 추가
        )
    }
    
    func makeCreatePillCycleUseCase() -> CreatePillCycleUseCaseProtocol {
        return CreatePillCycleUseCase(
            cycleRepository: makePillCycleRepository(),
            timeProvider: timeProvider  // 추가
        )
    }
    
    // MARK: - ViewModels
    
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(
            fetchDashboardDataUseCase: makeFetchDashboardDataUseCase(),
            takePillUseCase: makeTakePillUseCase(),
            updatePillStatusUseCase: makeUpdatePillStatusUseCase(),
            calculateDashboardMessageUseCase: makeCalculateDashboardMessageUseCase(),
            userDefaultsManager: makeUserDefaultsManager()
        )
    }
    
    func makePillSettingViewModel() -> PillSettingViewModel {
        return PillSettingViewModel(userDefaultsManager: makeUserDefaultsManager())
    }
    
    func makeTimeSettingViewModel() -> TimeSettingViewModel {
        return TimeSettingViewModel(
            settingsRepository: makeUserSettingsRepository(),
            notificationManager: makeNotificationManager(),
            userDefaultsManager: makeUserDefaultsManager(),
            createPillCycleUseCase: makeCreatePillCycleUseCase()
        )
    }
    
    func makeTimeSettingViewController() -> TimeSettingViewController {
        let viewModel = makeTimeSettingViewModel()
        return TimeSettingViewController(viewModel: viewModel)
    }
    
    func makeSettingViewModel() -> SettingViewModel {
        return SettingViewModel(
            settingsRepository: makeUserSettingsRepository(),
            notificationManager: makeNotificationManager(),
            pillCycleRepository: makePillCycleRepository(),
            userDefaultsManager: makeUserDefaultsManager()
        )
    }
    
    func makeSettingViewController() -> SettingViewController {
        let viewModel = makeSettingViewModel()
        return SettingViewController(viewModel: viewModel)
    }
    
    // MARK: - History
    
    func makePillCycleHistoryViewModel() -> PillCycleHistoryViewModel {
        return PillCycleHistoryViewModel(context: coreDataManager.viewContext)
    }
}
