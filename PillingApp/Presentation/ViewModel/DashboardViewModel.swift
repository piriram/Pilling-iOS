//
//  DashboardViewModel.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - DashboardViewModel

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
    let currentCycle = BehaviorRelay<Cycle?>(value: nil)
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
        
        
        loadDashboardData()
        loadPillInfo()
    }
    
    // MARK: - Private Methods
    
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
        } else{
            print("pillInfo 불로오기 실패")
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
    
    private func reloadSettings() {
        settingsRepository.fetchSettings()
            .subscribe(onNext: { [weak self] settings in
                guard let self = self else { return }
                self.settings.accept(settings)
                
                // 현재 사이클의 scheduledTime도 업데이트
                if var cycle = self.currentCycle.value {
                    cycle.scheduledTime = settings.scheduledTime.formatted(style: .time24Hour)
                    self.currentCycle.accept(cycle)
                    self.updateItems()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func updateItems() {
        guard let cycle = currentCycle.value else { return }
        
        let maxItems = 28
        let visibleRecords = Array(cycle.records.prefix(maxItems))
        let now = Date()
        
        // 현재 설정된 복용 시간 가져오기
        let currentScheduledTime = settings.value.scheduledTime
        
        let dayItems = visibleRecords.map { record in
            var adjustedStatus = record.status.adjustedForDate(record.scheduledDateTime, calendar: calendar)
            
            // 오늘 날짜인 경우, 현재 설정 시간 기준으로 재계산
            if calendar.isDateInToday(record.scheduledDateTime) {
                // 오늘 날짜의 실제 예정 시간을 현재 설정 기준으로 다시 계산
                let todayScheduledDateTime = calculateTodayScheduledTime(
                    from: currentScheduledTime,
                    calendar: calendar
                )
                
                // 휴약 기간이 아닌 경우
                if adjustedStatus != .rest {
                    // takenDouble은 재계산하지 않고 그대로 유지
                    if record.status == .takenDouble {
                        adjustedStatus = .takenDouble
                    }
                    // 복용하지 않은 경우: 지연 시간 체크
                    else if !adjustedStatus.isTaken {
                        let timeInterval = now.timeIntervalSince(todayScheduledDateTime)
                        let twoHours: TimeInterval = 2 * 60 * 60
                        let fourHours: TimeInterval = 4 * 60 * 60
                        
                        if timeInterval >= fourHours {
                            adjustedStatus = .todayDelayedCritical
                        } else if timeInterval >= twoHours {
                            adjustedStatus = .todayDelayed
                        } else {
                            adjustedStatus = .todayNotTaken
                        }
                    }
                    // 복용한 경우: takenAt 기준으로 상태 재계산
                    else if let takenAt = record.takenAt {
                        adjustedStatus = calculateTakenStatus(
                            takenAt: takenAt,
                            scheduledDateTime: todayScheduledDateTime
                        )
                    }
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
    
    /// 오늘 날짜에 현재 설정된 복용 시간을 적용한 Date 계산
    private func calculateTodayScheduledTime(
        from scheduledTime: Date,
        calendar: Calendar
    ) -> Date {
        let now = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        
        var combined = DateComponents()
        combined.year = todayComponents.year
        combined.month = todayComponents.month
        combined.day = todayComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? now
    }
    
    /// 실제 복용 시간과 예정 시간을 비교하여 복용 상태 계산
    private func calculateTakenStatus(
        takenAt: Date,
        scheduledDateTime: Date
    ) -> PillStatus {
        let timeInterval = takenAt.timeIntervalSince(scheduledDateTime)
        let twoHours: TimeInterval = 2 * 60 * 60
        
        // 2시간 이상 일찍 복용
        if timeInterval < -twoHours {
            return .todayTakenTooEarly
        }
        // 2시간 이상 늦게 복용
        else if timeInterval > twoHours {
            return .todayTakenDelayed
        }
        // 정상 범위 내 복용
        else {
            return .todayTaken
        }
    }
    
    private func updateDashboardMessage() {
        let message = calculateDashboardMessageUseCase.execute(cycle: currentCycle.value)
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
    
    /// Dashboard 화면 진입 시 현재 날짜 기준으로 UI를 갱신
    func refreshForCurrentDate() {
        guard let cycle = currentCycle.value else {
            updateItems()
            updateDashboardMessage()
            updateCanTakePill()
            return
        }
        
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        // 과거에 scheduled 상태인 레코드가 있는지 확인
        let hasPastScheduled = cycle.records.contains { record in
            record.scheduledDateTime < startOfToday && record.status == .scheduled
        }
        
        if hasPastScheduled {
            // 과거 scheduled를 먼저 missed로 변환
            // UI 업데이트는 autoMarkPastScheduledAsMissed의 subscribe에서 자동으로 처리됨
            autoMarkPastScheduledAsMissed()
        } else {
            // 과거 scheduled가 없으면 바로 UI 업데이트
            updateItems()
            updateDashboardMessage()
            updateCanTakePill()
        }
    }
    
    /// 설정 변경 후 화면 복귀 시 최신 설정 및 사이클 데이터 다시 로드
    func reloadData() {
        loadDashboardData()
//        loadPillInfo()
    }
    
    /// 설정 변경 후 UI 업데이트 (설정값만 다시 로드)
    func refreshSettings() {
        reloadSettings()
        
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
        guard let cycle = currentCycle.value else {
            print("❌ updateState: cycle이 nil입니다")
            return
        }
        
        updatePillStatusUseCase.execute(
            cycle: cycle,
            recordIndex: index,
            newStatus: newStatus,
            memo: memo
        )
        .subscribe(
            onNext: { [weak self] updatedCycle in
                
                if index < updatedCycle.records.count {
                }
                
                self?.currentCycle.accept(updatedCycle)
                
                self?.updateItems()
                
                self?.updateDashboardMessage()
                
                self?.updateCanTakePill()
            },
            onError: { error in
                print("❌ UseCase 에러: \(error)")
            }
        )
        .disposed(by: disposeBag)
    }
}
