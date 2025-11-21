//
//  CoreDataCycleRepository.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//
// MARK: - 복용 사이클 데이터를 rx로 다룸 & 위젯 갱신까지 책임
// TODO: - 위젯에 새약 설정해야하는 것도 설정하기
import CoreData
import RxSwift
import WidgetKit

final class CycleRepository: CycleRepositoryProtocol {
    
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        print("순서:\(#fileID)")
        
        self.coreDataManager = coreDataManager
    }
    
    
    // 주어진 날짜가 시작일과 종료일 사이인지 판별
    private func isOngoingCycle(_ cycle: Cycle, at date: Date) -> Bool {
        let calendar = Calendar.current
        let startDate = cycle.startDate
        let endDate = calendar.date(
            byAdding: .day,
            value: cycle.totalDays - 1,
            to: startDate
        ) ?? startDate
        
        return startDate <= date && date <= endDate
    }
    
    
    // MARK: - 현재 사이클 조회(DB 조회 비용 있음)
    func fetchCurrentCycle() -> Observable<Cycle?> {
        return coreDataManager
            .fetch(
                entityType: PillCycleEntity.self,
                sortDescriptors: [
                    NSSortDescriptor(key: "createdAt", ascending: false),
                    NSSortDescriptor(key: "startDate", ascending: false)
                ]
            )
            .map { [weak self] entities in
                print("🔍 [CycleRepository] fetchCurrentCycle 호출")
                print("   📊 조회된 사이클 수: \(entities.count)")

                let cycles = entities.map { $0.toDomain() }
                let now = Date()

                // 진행 중 사이클 우선
                if let ongoingCycle = cycles.first(where: {
                    self?.isOngoingCycle($0, at: now) ?? false
                }) {
                    print("   ✅ 진행 중 사이클 발견")
                    print("   📝 레코드 수: \(ongoingCycle.records.count)")
                    for (index, record) in ongoingCycle.records.enumerated() {
                        print("      [\(index)] memo: '\(record.memo)'")
                    }
                    return ongoingCycle
                }

                // 없으면 최신 사이클
                if let latestCycle = cycles.first {
                    print("   ✅ 최신 사이클 반환")
                    print("   📝 레코드 수: \(latestCycle.records.count)")
                    for (index, record) in latestCycle.records.enumerated() {
                        print("      [\(index)] memo: '\(record.memo)'")
                    }
                }
                return cycles.first
            }
    }
    
    func saveCycle(_ cycle: Cycle) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.coreDataManager.viewContext
            
            // 기존 사이클이 있는지 확인
            let fetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: CoreDataEntity.cycle)
            fetchRequest.predicate = NSPredicate(format: "id == %@", cycle.id as CVarArg)
            
            do {
                let existingCycles = try context.fetch(fetchRequest)
                
                if let existingCycle = existingCycles.first {
                    // 업데이트
                    existingCycle.update(from: cycle)
                    
                    // 기존 레코드들 삭제 후 새로 추가
                    if let records = existingCycle.records {
                        existingCycle.removeFromRecords(records)
                    }
                    
                    cycle.records.forEach { record in
                        let recordEntity = PillRecordEntity.from(domain: record, context: context)
                        recordEntity.cycle = existingCycle
                    }
                } else {
                    // 새로 생성
                    _ = PillCycleEntity.from(domain: cycle, context: context)
                }
                
                try context.save()
                
                WidgetCenter.shared.reloadAllTimelines()
                print("💊 사이클 저장 완료 - 위젯 업데이트")
                
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.saveFailed(error))
            }
            
            return Disposables.create()
        }
    }
    
    func updateRecord(_ record: DayRecord, in cycleID: UUID) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }

            // 🔍 [디버깅] Repository 진입점
            print("🔍 [CycleRepository] updateRecord 호출")
            print("   🆔 cycleID: \(cycleID)")
            print("   📝 record.id: \(record.id)")
            print("   💾 record.memo: '\(record.memo)'")
            print("   ✅ record.status: \(record.status)")

            let context = self.coreDataManager.viewContext

            // 사이클 찾기
            let cycleFetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: "PillCycleEntity")
            cycleFetchRequest.predicate = NSPredicate(format: "id == %@", cycleID as CVarArg)

            do {
                guard let PillCycleEntity = try context.fetch(cycleFetchRequest).first else {
                    print("   ❌ Cycle을 찾을 수 없음: \(cycleID)")
                    observer.onError(CoreDataError.invalidData)
                    return Disposables.create()
                }

                print("   ✅ Cycle 찾음")

                // 레코드 찾기
                let recordFetchRequest: NSFetchRequest<PillRecordEntity> = NSFetchRequest(entityName: "PillRecordEntity")
                recordFetchRequest.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)

                if let recordEntity = try context.fetch(recordFetchRequest).first {
                    // 업데이트
                    print("   📝 기존 레코드 업데이트")
                    print("      저장 전 Entity.memo: '\(recordEntity.memo ?? "nil")'")
                    recordEntity.update(from: record)
                    print("      저장 후 Entity.memo: '\(recordEntity.memo ?? "nil")'")
                } else {
                    // 새로 생성
                    print("   🆕 새 레코드 생성")
                    let newRecordEntity = PillRecordEntity.from(domain: record, context: context)
                    newRecordEntity.cycle = PillCycleEntity
                    print("      생성된 Entity.memo: '\(newRecordEntity.memo ?? "nil")'")
                }

                try context.save()
                print("   💾 CoreData 저장 완료")

                // 저장 후 검증
                if let savedEntity = try context.fetch(recordFetchRequest).first {
                    print("   🔍 저장 검증 - Entity.memo: '\(savedEntity.memo ?? "nil")'")
                }

                // ⭐️ 위젯 업데이트
                WidgetCenter.shared.reloadAllTimelines()
                print("💊 복용 기록 업데이트 완료 - 위젯 업데이트")

                observer.onNext(())
                observer.onCompleted()
            } catch {
                print("   ❌ CoreData 저장 실패: \(error)")
                observer.onError(CoreDataError.saveFailed(error))
            }

            return Disposables.create()
        }
    }
    
    // MARK: - Additional Methods
    
    func deleteAllCycles() -> Observable<Void> {
        return coreDataManager.deleteAll(entityType: PillCycleEntity.self)
            .do(onNext: {
                WidgetCenter.shared.reloadAllTimelines()
                print("🗑️ 모든 사이클 삭제 완료 - 위젯 업데이트")
            })
    }
    
    func fetchAllCycles() -> Observable<[Cycle]> {
        return coreDataManager
            .fetch(
                entityType: PillCycleEntity.self,
                sortDescriptors: [
                    NSSortDescriptor(key: "createdAt", ascending: false),
                    NSSortDescriptor(key: "startDate", ascending: false)
                ]
            )
            .map { entities in
                return entities.map { $0.toDomain() }
            }
    }
    
    func fetchCycle(by id: UUID) -> Observable<Cycle?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.coreDataManager.viewContext
            let fetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: "PillCycleEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                let cycle = results.first?.toDomain()
                observer.onNext(cycle)
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.fetchFailed(error))
            }
            
            return Disposables.create()
        }
    }
}


