//
//  UpdatePillStatusUseCaseTests.swift
//  PillingAppTests
//
//  Tests for UpdatePillStatusUseCase
//

import XCTest
import RxSwift
@testable import PillingApp

/// Tests for UpdatePillStatusUseCase
final class UpdatePillStatusUseCaseTests: XCTestCase {

    // MARK: - Properties

    var sut: UpdatePillStatusUseCase!
    var mockRepository: MockCycleRepository!
    var mockTimeProvider: MockTimeProvider!
    var disposeBag: DisposeBag!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockCycleRepository()
        mockTimeProvider = MockTimeProvider(now: Date())
        sut = UpdatePillStatusUseCase(
            cycleRepository: mockRepository,
            timeProvider: mockTimeProvider
        )
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockTimeProvider = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - Update Status Tests (15 tests)

    func test_updateStatus_validIndex_callsRepository() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let expectation = XCTestExpectation(description: "Update completes")

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 4, // Day 5 = index 4
            newStatus: .todayTaken,
            memo: "Test memo",
            takenAt: Date()
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockRepository.updateRecordCalled,
            "Repository updateRecord should be called")
        XCTAssertNotNil(mockRepository.lastUpdatedRecord,
            "Updated record should be stored")
        XCTAssertEqual(mockRepository.lastCycleId, cycle.id,
            "Cycle ID should match")
    }

    func test_updateStatus_updatesStatus() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let expectation = XCTestExpectation(description: "Update completes")

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .todayTaken,
            memo: nil,
            takenAt: Date()
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastUpdatedRecord?.status, .todayTaken,
            "Status should be updated to todayTaken")
    }

    func test_updateStatus_updatesMemo() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let expectation = XCTestExpectation(description: "Update completes")
        let testMemo = "Test memo"

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .todayTaken,
            memo: testMemo,
            takenAt: Date()
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastUpdatedRecord?.memo, testMemo,
            "Memo should be updated")
    }

    func test_updateStatus_updatesTakenAt() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let testDate = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 9, minute: 15)
        let expectation = XCTestExpectation(description: "Update completes")

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .todayTaken,
            memo: nil,
            takenAt: testDate
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastUpdatedRecord?.takenAt, testDate,
            "TakenAt should be updated to provided date")
    }

    func test_updateStatus_takenStatus_withoutProvidedTakenAt_usesNow() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let now = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 10, minute: 0)
        mockTimeProvider.now = now

        let expectation = XCTestExpectation(description: "Update completes")

        // When - Not providing takenAt for a taken status
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .todayTaken,
            memo: nil,
            takenAt: nil
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(mockRepository.lastUpdatedRecord?.takenAt,
            "TakenAt should be set to now for taken status")
    }

    func test_updateStatus_notTakenStatus_clearsTakenAt() {
        // Given
        let day5Start = DateTestHelper.addDays(to: TestConstants.defaultStartDate, days: 4)
        let previousTakenTime = DateTestHelper.makeTime("09:10", on: day5Start)

        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .todayStatus(.todayTaken)
            .withTakenAt(day: 5, takenAt: previousTakenTime)
            .build()

        let expectation = XCTestExpectation(description: "Update completes")

        // When - Changing to a non-taken status
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .scheduled,
            memo: nil,
            takenAt: nil
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(mockRepository.lastUpdatedRecord?.takenAt,
            "TakenAt should be nil for non-taken status")
    }

    func test_updateStatus_invalidIndex_returnsOriginalCycle() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let expectation = XCTestExpectation(description: "Returns original cycle")
        var result: Cycle?

        // When - Using invalid index
        sut.execute(
            cycle: cycle,
            recordIndex: 999,
            newStatus: .todayTaken,
            memo: nil,
            takenAt: Date()
        )
        .subscribe(onNext: { updatedCycle in
            result = updatedCycle
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(mockRepository.updateRecordCalled,
            "Repository should not be called for invalid index")
        XCTAssertEqual(result?.id, cycle.id,
            "Should return original cycle unchanged")
    }

    func test_updateStatus_preservesOtherRecordProperties() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let originalRecord = cycle.records[4] // Day 5
        let expectation = XCTestExpectation(description: "Update completes")

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .todayTaken,
            memo: "New memo",
            takenAt: Date()
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        let updatedRecord = mockRepository.lastUpdatedRecord!

        XCTAssertEqual(updatedRecord.id, originalRecord.id,
            "ID should be preserved")
        XCTAssertEqual(updatedRecord.cycleDay, originalRecord.cycleDay,
            "Cycle day should be preserved")
        XCTAssertEqual(updatedRecord.scheduledDateTime, originalRecord.scheduledDateTime,
            "Scheduled date/time should be preserved")
        XCTAssertEqual(updatedRecord.createdAt, originalRecord.createdAt,
            "Created at should be preserved")
    }

    func test_updateStatus_updatesUpdatedAt() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let now = DateTestHelper.makeDate(year: 2025, month: 1, day: 5, hour: 10, minute: 0)
        mockTimeProvider.now = now

        let expectation = XCTestExpectation(description: "Update completes")

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .todayTaken,
            memo: nil,
            takenAt: nil
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastUpdatedRecord?.updatedAt, now,
            "UpdatedAt should be set to current time")
    }

    func test_updateStatus_takenDouble_setsStatus() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .build()

        let expectation = XCTestExpectation(description: "Update completes")

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .takenDouble,
            memo: "Took 2 pills",
            takenAt: Date()
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastUpdatedRecord?.status, .takenDouble,
            "Status should be set to takenDouble")
    }

    func test_updateStatus_rest_canUpdate() {
        // Given
        let cycle = CycleBuilder()
            .withActiveDays(24)
            .withBreakDays(4)
            .scheduledTime("09:00")
            .build()

        let expectation = XCTestExpectation(description: "Update completes")

        // When - Updating a rest day record (day 25 = index 24)
        sut.execute(
            cycle: cycle,
            recordIndex: 24,
            newStatus: .rest,
            memo: "Rest day",
            takenAt: nil
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockRepository.updateRecordCalled,
            "Should be able to update rest day records")
    }

    func test_updateStatus_memoNil_preservesExistingMemo() {
        // Given
        let cycle = CycleBuilder()
            .day(5)
            .scheduledTime("09:00")
            .withMemo(day: 5, memo: "Existing memo")
            .build()

        let expectation = XCTestExpectation(description: "Update completes")

        // When - Not providing memo
        sut.execute(
            cycle: cycle,
            recordIndex: 4,
            newStatus: .todayTaken,
            memo: nil,
            takenAt: Date()
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockRepository.lastUpdatedRecord?.memo, "Existing memo",
            "Should preserve existing memo when nil is provided")
    }

    func test_updateStatus_firstDay_index0() {
        // Given
        let cycle = CycleBuilder()
            .day(1)
            .scheduledTime("09:00")
            .build()

        let expectation = XCTestExpectation(description: "Update completes")

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 0,
            newStatus: .todayTaken,
            memo: nil,
            takenAt: Date()
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockRepository.updateRecordCalled,
            "Should work for first day (index 0)")
        XCTAssertEqual(mockRepository.lastUpdatedRecord?.cycleDay, 1,
            "Should update day 1")
    }

    func test_updateStatus_lastDay_index27() {
        // Given
        let cycle = CycleBuilder()
            .day(28)
            .scheduledTime("09:00")
            .build()

        let expectation = XCTestExpectation(description: "Update completes")

        // When
        sut.execute(
            cycle: cycle,
            recordIndex: 27, // Last day
            newStatus: .rest,
            memo: nil,
            takenAt: nil
        )
        .subscribe(onNext: { _ in
            expectation.fulfill()
        })
        .disposed(by: disposeBag)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockRepository.updateRecordCalled,
            "Should work for last day (index 27)")
        XCTAssertEqual(mockRepository.lastUpdatedRecord?.cycleDay, 28,
            "Should update day 28")
    }
}
