//
//  DIContainer.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import UserNotifications

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
        LocalNotificationManager(
            notificationCenter: .current(),
            timeProvider: timeProvider
        )
    }
    
    
    func makeUserDefaultsManager() -> UserDefaultsManagerProtocol {
        return UserDefaultsManager()
    }
    
    // MARK: - Repositories
    
    func makePillCycleRepository() -> PillCycleRepositoryProtocol {
        return CoreDataPillCycleRepository(
            coreDataManager: coreDataManager,
            timeProvider: timeProvider
        )
    }
    
    func makeUserSettingsRepository() -> UserSettingsRepositoryProtocol {
        return UserDefaultsUserSettingsRepository()
    }
    
    // MARK: - UseCases
    
    func makeFetchDashboardDataUseCase() -> GetDashboardSnapshotUseCaseProtocol {
        return GetDashboardSnapshotUseCase(
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
    
    // DIContainer.swift에 추가
    func makePillStatusEvaluator() -> PillStatusEvaluator {
        return PillStatusEvaluator(timeProvider: timeProvider)
    }
    
    func makeCalculateDashboardMessageUseCase() -> CalculateDashboardMessageUseCaseProtocol {
        return CalculateDashboardMessageUseCase(
            statusEvaluator: makePillStatusEvaluator(),
            timeProvider: timeProvider
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
            userDefaultsManager: makeUserDefaultsManager(),
            settingsRepository: makeUserSettingsRepository(),
            timeProvider: timeProvider
        )
    }
    
    func makeDashboardViewController() -> DashboardViewController {
        let vm = makeDashboardViewModel()
        return DashboardViewController(viewModel: vm, timeProvider: timeProvider)
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
            userDefaultsManager: makeUserDefaultsManager(), timeProvider: timeProvider
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

