//
//  DashboardViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Presentation/Dashboard/ViewModels/DashboardViewModel.swift

final class DashboardViewModel {
    
    private let fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol
    private let takePillUseCase: TakePillUseCaseProtocol
    private let updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol
    private let calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let settingsRepository: UserSettingsRepositoryProtocol
    
    private let disposeBag = DisposeBag()
    private let calendar = Calendar.current
    
    // MARK: - Outputs
    
    let settings = BehaviorRelay<UserSettings>(value: .default)
    let currentCycle = BehaviorRelay<PillCycle?>(value: nil)
    let items = BehaviorRelay<[DayItem]>(value: [])
    let dashboardMessage = BehaviorRelay<DashboardMessage?>(value: nil)
    let canTakePill = BehaviorRelay<Bool>(value: false)
    let pillInfo = BehaviorRelay<PillInfo?>(value: nil)
    
    // MARK: - Initialization
    
    init(
        fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol,
        takePillUseCase: TakePillUseCaseProtocol,
        updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol,
        calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol,
        userDefaultsManager: UserDefaultsManagerProtocol,
        settingsRepository: UserSettingsRepositoryProtocol
    ) {
        self.fetchDashboardDataUseCase = fetchDashboardDataUseCase
        self.takePillUseCase = takePillUseCase
        self.updatePillStatusUseCase = updatePillStatusUseCase
        self.calculateDashboardMessageUseCase = calculateDashboardMessageUseCase
        self.userDefaultsManager = userDefaultsManager
        self.settingsRepository = settingsRepository
        
        loadPillInfo()
        loadDashboardData()
    }
    
    // MARK: - Private Methods
    
    private func reloadSettings() {
        settingsRepository.fetchSettings()
            .subscribe(onNext: { [weak self] settings in
                guard let self = self else { return }
                self.settings.accept(settings)
                
                // 현재 사이클의 scheduledTime도 업데이트
                if var cycle = self.currentCycle.value {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    cycle.scheduledTime = formatter.string(from: settings.scheduledTime)
                    self.currentCycle.accept(cycle)
                    self.updateItems()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func autoMarkPastScheduledAsMissed() {
        guard let cycle = currentCycle.value else { return }
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        for (index, record) in cycle.records.enumerated() {
            if record.scheduledDateTime < startOfToday {
                if case .scheduled = record.status {
                    updatePillStatusUseCase
                        .execute(
                            cycle: cycle,
                            recordIndex: index,
                            newStatus: .missed,
                            memo: nil
                        )
                        .subscribe(onNext: { [weak self] updatedCycle in
                            self?.currentCycle.accept(updatedCycle)
                            self?.updateItems()
                            self?.updateDashboardMessage()
                            self?.updateCanTakePill()
                        })
                        .disposed(by: disposeBag)
                }
            }
        }
    }
    
    private func loadPillInfo() {
        if let info = userDefaultsManager.loadPillInfo() {
            pillInfo.accept(info)
        }
    }
    
    private func loadDashboardData() {
        fetchDashboardDataUseCase.execute()
            .subscribe(onNext: { [weak self] data in
                self?.settings.accept(data.settings)
                self?.currentCycle.accept(data.cycle)
                self?.updateItems()
                self?.updateDashboardMessage()
                self?.updateCanTakePill()
                self?.autoMarkPastScheduledAsMissed()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateItems() {
        guard let cycle = currentCycle.value else { return }
        
        let maxItems = 28
        let visibleRecords = Array(cycle.records.prefix(maxItems))
        let now = Date()
        
        let dayItems = visibleRecords.map { record in
            var adjustedStatus = record.status.adjustedForDate(record.scheduledDateTime, calendar: calendar)
            
            // 오늘 날짜이고 아직 복용하지 않았으며 지연 시간 체크
            if calendar.isDateInToday(record.scheduledDateTime),
               !adjustedStatus.isTaken,
               adjustedStatus != .rest {
                let timeInterval = now.timeIntervalSince(record.scheduledDateTime)
                let twoHours: TimeInterval = 2 * 60 * 60
                let fourHours: TimeInterval = 4 * 60 * 60
                
                if timeInterval >= fourHours {
                    adjustedStatus = .todayDelayedCritical
                } else if timeInterval >= twoHours {
                    adjustedStatus = .todayDelayed
                }
            }
            
            return DayItem(
                cycleDay: record.cycleDay,
                date: record.scheduledDateTime,
                status: adjustedStatus,
                scheduledDateTime: record.scheduledDateTime
            )
        }
        
        items.accept(dayItems)
    }
    
    private func updateDashboardMessage() {
        let message = calculateDashboardMessageUseCase.execute(
            cycle: currentCycle.value,
            items: items.value
        )
        dashboardMessage.accept(message)
    }
    
    private func updateCanTakePill() {
        guard let cycle = currentCycle.value else {
            canTakePill.accept(false)
            return
        }
        
        let now = Date()
        
        guard let todayRecord = cycle.records.first(where: {
            calendar.isDate($0.scheduledDateTime, inSameDayAs: now)
        }) else {
            canTakePill.accept(false)
            return
        }
        
        if case .rest = todayRecord.status {
            canTakePill.accept(false)
            return
        }
        
        let adjustedStatus = todayRecord.status.adjustedForDate(todayRecord.scheduledDateTime, calendar: calendar)
        if adjustedStatus.isTaken {
            canTakePill.accept(false)
            return
        }
        
        canTakePill.accept(true)
    }
    
    // MARK: - Public Methods (Inputs)
    
    /// 설정 변경 후 UI 업데이트 (설정값만 다시 로드)
    func refreshSettings() {
        reloadSettings()
    }
    
    /// Dashboard 화면 진입 시 현재 날짜 기준으로 UI를 갱신
    func refreshForCurrentDate() {
        updateItems()
        updateDashboardMessage()
        updateCanTakePill()
        autoMarkPastScheduledAsMissed()
    }
    
    func takePill() {
        guard let cycle = currentCycle.value else { return }
        
        takePillUseCase.execute(cycle: cycle, settings: settings.value)
            .subscribe(onNext: { [weak self] updatedCycle in
                self?.currentCycle.accept(updatedCycle)
                self?.updateItems()
                self?.updateDashboardMessage()
                self?.updateCanTakePill()
            })
            .disposed(by: disposeBag)
    }
    
    func updateState(at index: Int, to newStatus: PillStatus) {
        guard let cycle = currentCycle.value else { return }
        
        updatePillStatusUseCase.execute(
            cycle: cycle,
            recordIndex: index,
            newStatus: newStatus,
            memo: nil
        )
        .subscribe(onNext: { [weak self] updatedCycle in
            self?.currentCycle.accept(updatedCycle)
            self?.updateItems()
            self?.updateDashboardMessage()
            self?.updateCanTakePill()
        })
        .disposed(by: disposeBag)
    }
    
    func updateState(at index: Int, to newStatus: PillStatus, memo: String?) {
        guard let cycle = currentCycle.value else { return }
        
        updatePillStatusUseCase.execute(
            cycle: cycle,
            recordIndex: index,
            newStatus: newStatus,
            memo: memo
        )
        .subscribe(onNext: { [weak self] updatedCycle in
            self?.currentCycle.accept(updatedCycle)
            self?.updateItems()
            self?.updateDashboardMessage()
            self?.updateCanTakePill()
        })
        .disposed(by: disposeBag)
    }
}

