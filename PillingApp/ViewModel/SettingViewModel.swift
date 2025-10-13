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
        let alarmToggleChanged: Observable<Bool>
        let healthToggleChanged: Observable<Bool>
    }
    
    struct Output {
        let currentSettings: Driver<UserSettings>
        let showTimePicker: Driver<Void>
        let showMessageEditor: Driver<String>
        let showError: Driver<String>
        let showSuccess: Driver<String>
    }
    
    // MARK: - Properties
    
    private let settingsRepository: UserSettingsRepositoryProtocol
    private let notificationManager: NotificationManagerProtocol
    private let disposeBag = DisposeBag()
    
    private let currentSettingsRelay = BehaviorRelay<UserSettings>(value: .default)
    
    // MARK: - Initialization
    
    init(
        settingsRepository: UserSettingsRepositoryProtocol,
        notificationManager: NotificationManagerProtocol
    ) {
        self.settingsRepository = settingsRepository
        self.notificationManager = notificationManager
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
        
        // 알람 토글 변경 시 즉시 저장 및 알림 업데이트
        input.alarmToggleChanged
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
        
        // Health 토글 변경 시 즉시 저장
        input.healthToggleChanged
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
        
        let showTimePicker = input.timeSettingTapped
            .asDriver(onErrorJustReturn: ())
        
        let showMessageEditor = input.messageSettingTapped
            .withLatestFrom(currentSettingsRelay.asObservable())
            .map { $0.notificationMessage }
            .asDriver(onErrorJustReturn: "")
        
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
            showSuccess: showSuccess
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
        
        // 1. 설정 저장
        return settingsRepository.saveSettings(updatedSettings)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 2. 알림 재설정 (알림이 활성화된 경우에만)
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
        
        // 1. 설정 저장
        return settingsRepository.saveSettings(updatedSettings)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 2. 알림 재설정 (알림이 활성화된 경우에만)
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
    
    // MARK: - Private Methods
    
    private func updateAlarmSetting(isEnabled: Bool) -> Observable<Void> {
        let currentSettings = currentSettingsRelay.value
        
        let updatedSettings = UserSettings(
            scheduledTime: currentSettings.scheduledTime,
            notificationEnabled: isEnabled,
            delayThresholdMinutes: currentSettings.delayThresholdMinutes,
            notificationMessage: currentSettings.notificationMessage
        )
        
        // 1. 알림 권한 확인 및 스케줄링
        return notificationManager.requestAuthorization()
            .flatMap { [weak self] granted -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                guard granted else {
                    return .error(NotificationError.permissionDenied)
                }
                
                // 2. 알림 스케줄링 (비활성화 시 기존 알림 삭제)
                return self.notificationManager.scheduleDailyNotification(
                    at: currentSettings.scheduledTime,
                    isEnabled: isEnabled,
                    message: currentSettings.notificationMessage
                )
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 3. 설정 저장
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
