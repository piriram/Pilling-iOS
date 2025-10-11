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
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Outputs
    
    let settings = BehaviorRelay<UserSettings>(value: .default)
    let currentCycle = BehaviorRelay<PillCycle?>(value: nil)
    let items = BehaviorRelay<[DayItem]>(value: [])
    let dashboardMessage = BehaviorRelay<DashboardMessage?>(value: nil)
    let canTakePill = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Initialization
    
    init(
        fetchDashboardDataUseCase: FetchDashboardDataUseCaseProtocol,
        takePillUseCase: TakePillUseCaseProtocol,
        updatePillStatusUseCase: UpdatePillStatusUseCaseProtocol,
        calculateDashboardMessageUseCase: CalculateDashboardMessageUseCaseProtocol
    ) {
        self.fetchDashboardDataUseCase = fetchDashboardDataUseCase
        self.takePillUseCase = takePillUseCase
        self.updatePillStatusUseCase = updatePillStatusUseCase
        self.calculateDashboardMessageUseCase = calculateDashboardMessageUseCase
        
        loadDashboardData()
    }
    
    // MARK: - Private Methods
    
    private func loadDashboardData() {
        fetchDashboardDataUseCase.execute()
            .subscribe(onNext: { [weak self] data in
                self?.settings.accept(data.settings)
                self?.currentCycle.accept(data.cycle)
                self?.updateItems()
                self?.updateDashboardMessage()
                self?.updateCanTakePill()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateItems() {
        guard let cycle = currentCycle.value else { return }
        
        let dayItems = cycle.records.map { record in
            DayItem(
                cycleDay: record.cycleDay,
                date: record.scheduledDateTime,
                status: record.status
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
        
        let calendar = Calendar.current
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
        
        if todayRecord.status.isTaken {
            canTakePill.accept(false)
            return
        }
        
        canTakePill.accept(true)
    }
    
    // MARK: - Public Methods (Inputs)
    
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
            newStatus: newStatus
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
