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
    
    // MARK: - Time Provider
    
    lazy var timeProvider: TimeProvider = {
        SystemTimeProvider()
    }()
    
    // MARK: - Managers(싱글톤)
    
    private lazy var userDefaultsManager: UserDefaultsManagerProtocol = {
        return UserDefaultsManager()
    }()
    
    private lazy var notificationManager: NotificationManagerProtocol = {
        return LocalNotificationManager()
    }()
    
    // MARK: - Repositories (싱글톤)
    
    private lazy var cycleRepository: CycleRepositoryProtocol = {
        return CycleRepository(coreDataManager: coreDataManager)
    }()
    
    private lazy var settingsRepository: UserDefaultsProtocol = {
        return UserDefaultsRepository()
    }()
    
    // MARK: - UseCases
    
    func makeFetchDashboardDataUseCase() -> FetchDashboardDataUseCaseProtocol {
        return FetchDashboardDataUseCase(
            cycleRepository: cycleRepository,
            settingsRepository: settingsRepository,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    func makeTakePillUseCase() -> TakePillUseCaseProtocol {
        return TakePillUseCase(
            cycleRepository: cycleRepository,
            timeProvider: timeProvider
        )
    }
    
    func makeUpdatePillStatusUseCase() -> UpdatePillStatusUseCaseProtocol {
        return UpdatePillStatusUseCase(
            cycleRepository: cycleRepository,
            timeProvider: timeProvider
        )
    }
    
    func makeCalculateDashboardMessageUseCase() -> CalculateDashboardMessageUseCaseProtocol {
        return CalculateDashboardMessageUseCase(
            timeProvider: timeProvider
        )
    }
    
    func makeCreatePillCycleUseCase() -> CreateCycleUseCaseProtocol {
        return CreateCycleUseCase(
            cycleRepository: cycleRepository,
            timeProvider: timeProvider,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    // MARK: - ViewModels
    
    func makeDashboardViewModel() -> DashboardViewModel {
        return DashboardViewModel(
            fetchDashboardDataUseCase: makeFetchDashboardDataUseCase(),
            takePillUseCase: makeTakePillUseCase(),
            updatePillStatusUseCase: makeUpdatePillStatusUseCase(),
            calculateDashboardMessageUseCase: makeCalculateDashboardMessageUseCase(),
            userDefaultsManager: userDefaultsManager,
            settingsRepository: settingsRepository
        )
    }
    
    func makePillSettingViewModel() -> PillSettingViewModel {
        return PillSettingViewModel(userDefaultsManager: userDefaultsManager)
    }
    
    func makeTimeSettingViewModel() -> TimeSettingViewModel {
        return TimeSettingViewModel(
            settingsRepository: settingsRepository,
            notificationManager: notificationManager,
            userDefaultsManager: userDefaultsManager,
            createPillCycleUseCase: makeCreatePillCycleUseCase()
        )
    }
    
    func makeTimeSettingViewController() -> TimeSettingViewController {
        let viewModel = makeTimeSettingViewModel()
        return TimeSettingViewController(viewModel: viewModel)
    }
    
    func makeSettingViewModel() -> SettingViewModel {
        return SettingViewModel(
            settingsRepository: settingsRepository,
            notificationManager: notificationManager,
            pillCycleRepository: cycleRepository,
            userDefaultsManager: userDefaultsManager
        )
    }
    
    func makeSettingViewController() -> SettingViewController {
        let viewModel = makeSettingViewModel()
        return SettingViewController(viewModel: viewModel)
    }
    
    // MARK: - History
    
    func makePillCycleHistoryViewModel() -> CycleHistoryViewModel {
        return CycleHistoryViewModel(context: coreDataManager.viewContext)
    }
    
    func makeStasticsViewModel() -> StatisticsViewModel {
        return StatisticsViewModel()
    }
    
    func getPillCycleRepository() -> CycleRepositoryProtocol {
        return cycleRepository
    }
    
    func getUserDefaultsManager() -> UserDefaultsManagerProtocol {
        return userDefaultsManager
    }
}
