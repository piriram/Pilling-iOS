//
//  MockCycleRepository.swift
//  PillingAppTests
//
//  Mock implementation of CycleRepositoryProtocol for testing
//

import Foundation
import RxSwift
@testable import PillingApp

/// Mock repository for testing UpdatePillStatusUseCase
final class MockCycleRepository: CycleRepositoryProtocol {

    // MARK: - Mock Data

    var updateRecordCalled = false
    var lastUpdatedRecord: DayRecord?
    var lastCycleId: UUID?
    var updateRecordResult: Observable<Void> = .just(())

    // MARK: - CycleRepositoryProtocol Implementation

    func updateRecord(_ record: DayRecord, in cycleId: UUID) -> Observable<Void> {
        updateRecordCalled = true
        lastUpdatedRecord = record
        lastCycleId = cycleId
        return updateRecordResult
    }

    // Note: Only implementing methods needed for tests
    // Other methods would throw fatalError if called

    func createCycle(
        activeDays: Int,
        breakDays: Int,
        startDate: Date,
        scheduledTime: String
    ) -> Observable<Cycle> {
        fatalError("Not implemented in mock")
    }

    func getCurrentCycle() -> Observable<Cycle?> {
        fatalError("Not implemented in mock")
    }

    func getAllCycles() -> Observable<[Cycle]> {
        fatalError("Not implemented in mock")
    }

    func deleteCycle(_ cycleId: UUID) -> Observable<Void> {
        fatalError("Not implemented in mock")
    }

    func updateCycleScheduledTime(_ cycleId: UUID, scheduledTime: String) -> Observable<Void> {
        fatalError("Not implemented in mock")
    }
}
