//
//  SettingViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import Foundation
import RxSwift
import RxCocoa

final class SettingViewModel {
    
    // MARK: - Input/Output
    
    struct Input {
        let viewWillAppear: Observable<Void>
        let timeSettingTapped: Observable<Void>
        let messageSettingTapped: Observable<Void>
        let alarmToggleChanged: Observable<Bool>?
        let healthToggleChanged: Observable<Bool>?
        let newPillCycleTapped: Observable<Void>

        init(
            viewWillAppear: Observable<Void>,
            timeSettingTapped: Observable<Void>,
            messageSettingTapped: Observable<Void>,
            alarmToggleChanged: Observable<Bool>? = nil,
            healthToggleChanged: Observable<Bool>? = nil,
            newPillCycleTapped: Observable<Void>
        ) {
            self.viewWillAppear = viewWillAppear
            self.timeSettingTapped = timeSettingTapped
            self.messageSettingTapped = messageSettingTapped
            self.alarmToggleChanged = alarmToggleChanged
            self.healthToggleChanged = healthToggleChanged
            self.newPillCycleTapped = newPillCycleTapped
        }
    }
    
    struct Output {
        let currentSettings: Driver<UserSettings>
        let showTimePicker: Driver<Void>
        let showMessageEditor: Driver<String>
        let showError: Driver<String>
        let showSuccess: Driver<String>
        let showNewPillCycleConfirmation: Driver<Void>
        let navigateToPillSetting: Driver<Void>
    }
    
    // MARK: - Properties
    
    private let settingsRepository: UserSettingsRepositoryProtocol
    private let notificationManager: NotificationManagerProtocol
    private let pillCycleRepository: PillCycleRepositoryProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let disposeBag = DisposeBag()
    
    private let currentSettingsRelay = BehaviorRelay<UserSettings>(value: .default)
    private let navigateToPillSettingSubject = PublishSubject<Void>()
    
    // MARK: - Initialization
    
    init(
        settingsRepository: UserSettingsRepositoryProtocol,
        notificationManager: NotificationManagerProtocol,
        pillCycleRepository: PillCycleRepositoryProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol
    ) {
        self.settingsRepository = settingsRepository
        self.notificationManager = notificationManager
        self.pillCycleRepository = pillCycleRepository
        self.userDefaultsManager = userDefaultsManager
    }
    
    // MARK: - Transform
    
    func transform(input: Input) -> Output {
        let errorTracker = PublishSubject<String>()
        let successTracker = PublishSubject<String>()
        
        // 화면 진입 시 현재 설정 로드
        input.viewWillAppear
            .flatMapLatest { [weak self] _ -> Observable<UserSettings> in
                guard let self = self else { return .empty() }
                return self.settingsRepository.fetchSettings()
            }
            .bind(to: currentSettingsRelay)
            .disposed(by: disposeBag)
        
        // 알람 토글 변경 시 즉시 저장 및 알림 업데이트 (옵션)
        if let alarmChanged = input.alarmToggleChanged {
            alarmChanged
                .flatMapLatest { [weak self] isEnabled -> Observable<Void> in
                    guard let self = self else { return .empty() }
                    return self.updateAlarmSetting(isEnabled: isEnabled)
                        .do(onNext: {
                            successTracker.onNext("알림 설정이 변경되었습니다")
                        })
                        .catch { error in
                            errorTracker.onNext(self.handleError(error))
                            return .empty()
                        }
                }
                .subscribe()
                .disposed(by: disposeBag)
        }
        
        // Health 토글 변경 시 즉시 저장 (옵션)
        if let healthChanged = input.healthToggleChanged {
            healthChanged
                .flatMapLatest { [weak self] isEnabled -> Observable<Void> in
                    guard let self = self else { return .empty() }
                    return self.updateHealthSetting(isEnabled: isEnabled)
                        .do(onNext: {
                            successTracker.onNext("Health 연동 설정이 변경되었습니다")
                        })
                        .catch { error in
                            errorTracker.onNext(self.handleError(error))
                            return .empty()
                        }
                }
                .subscribe()
                .disposed(by: disposeBag)
        }
        
        let showTimePicker = input.timeSettingTapped
            .asDriver(onErrorJustReturn: ())
        
        let showMessageEditor = input.messageSettingTapped
            .withLatestFrom(currentSettingsRelay.asObservable())
            .map { $0.notificationMessage }
            .asDriver(onErrorJustReturn: "")
        
        let showNewPillCycleConfirmation = input.newPillCycleTapped
            .asDriver(onErrorJustReturn: ())
        
        let navigateToPillSetting = navigateToPillSettingSubject
            .asDriver(onErrorJustReturn: ())
        
        let currentSettings = currentSettingsRelay
            .asDriver(onErrorJustReturn: .default)
        
        let showError = errorTracker
            .asDriver(onErrorJustReturn: "알 수 없는 오류가 발생했습니다.")
        
        let showSuccess = successTracker
            .asDriver(onErrorJustReturn: "")
        
        return Output(
            currentSettings: currentSettings,
            showTimePicker: showTimePicker,
            showMessageEditor: showMessageEditor,
            showError: showError,
            showSuccess: showSuccess,
            showNewPillCycleConfirmation: showNewPillCycleConfirmation,
            navigateToPillSetting: navigateToPillSetting
        )
    }
    
    // MARK: - Public Methods
    
    func updateTime(_ date: Date) -> Observable<Void> {
        let currentSettings = currentSettingsRelay.value
        
        let updatedSettings = UserSettings(
            scheduledTime: date,
            notificationEnabled: currentSettings.notificationEnabled,
            delayThresholdMinutes: currentSettings.delayThresholdMinutes,
            notificationMessage: currentSettings.notificationMessage
        )
        
        return settingsRepository.saveSettings(updatedSettings)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                guard currentSettings.notificationEnabled else {
                    return .just(())
                }
                
                return self.notificationManager.scheduleDailyNotification(
                    at: date,
                    isEnabled: currentSettings.notificationEnabled,
                    message: currentSettings.notificationMessage
                )
            }
            .do(onNext: { [weak self] in
                self?.currentSettingsRelay.accept(updatedSettings)
            })
    }
    
    func updateMessage(_ message: String) -> Observable<Void> {
        let currentSettings = currentSettingsRelay.value
        
        let updatedSettings = UserSettings(
            scheduledTime: currentSettings.scheduledTime,
            notificationEnabled: currentSettings.notificationEnabled,
            delayThresholdMinutes: currentSettings.delayThresholdMinutes,
            notificationMessage: message
        )
        
        return settingsRepository.saveSettings(updatedSettings)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                guard currentSettings.notificationEnabled else {
                    return .just(())
                }
                
                return self.notificationManager.scheduleDailyNotification(
                    at: currentSettings.scheduledTime,
                    isEnabled: currentSettings.notificationEnabled,
                    message: message
                )
            }
            .do(onNext: { [weak self] in
                self?.currentSettingsRelay.accept(updatedSettings)
            })
    }
    
    func startNewPillCycle() -> Observable<Void> {
        // 1. 기존 사이클 삭제
        return pillCycleRepository.deleteAllCycles()
            .do(onNext: { [weak self] in
                // 2. UserDefaults 삭제
                self?.userDefaultsManager.clearPillSettings()
                
                // 3. 화면 전환 트리거
                self?.navigateToPillSettingSubject.onNext(())
            })
    }
    
    // MARK: - Private Methods
    
    private func updateAlarmSetting(isEnabled: Bool) -> Observable<Void> {
        let currentSettings = currentSettingsRelay.value
        
        let updatedSettings = UserSettings(
            scheduledTime: currentSettings.scheduledTime,
            notificationEnabled: isEnabled,
            delayThresholdMinutes: currentSettings.delayThresholdMinutes,
            notificationMessage: currentSettings.notificationMessage
        )
        
        return notificationManager.requestAuthorization()
            .flatMap { [weak self] granted -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                guard granted else {
                    return .error(NotificationError.permissionDenied)
                }
                
                return self.notificationManager.scheduleDailyNotification(
                    at: currentSettings.scheduledTime,
                    isEnabled: isEnabled,
                    message: currentSettings.notificationMessage
                )
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.settingsRepository.saveSettings(updatedSettings)
            }
            .do(onNext: { [weak self] in
                self?.currentSettingsRelay.accept(updatedSettings)
            })
    }
    
    private func updateHealthSetting(isEnabled: Bool) -> Observable<Void> {
        let currentSettings = currentSettingsRelay.value
        
        let updatedSettings = UserSettings(
            scheduledTime: currentSettings.scheduledTime,
            notificationEnabled: currentSettings.notificationEnabled,
            delayThresholdMinutes: currentSettings.delayThresholdMinutes,
            notificationMessage: currentSettings.notificationMessage
        )
        
        return settingsRepository.saveSettings(updatedSettings)
            .do(onNext: { [weak self] in
                self?.currentSettingsRelay.accept(updatedSettings)
            })
    }
    
    private func handleError(_ error: Error) -> String {
        if let notificationError = error as? NotificationError {
            switch notificationError {
            case .permissionDenied:
                return "알림 권한이 필요합니다.\n설정에서 알림을 허용해주세요."
            case .schedulingFailed:
                return "알림 설정에 실패했습니다.\n다시 시도해주세요."
            case .invalidTime:
                return "유효하지 않은 시간입니다."
            }
        }
        return "오류가 발생했습니다.\n다시 시도해주세요."
    }
}

