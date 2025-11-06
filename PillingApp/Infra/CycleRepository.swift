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
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - 현재 사이클 조회
    func fetchCurrentCycle() -> Observable<Cycle?> {
        return coreDataManager
            .fetch(
                entityType: PillCycleEntity.self,
                sortDescriptors: [
                    NSSortDescriptor(key: "createdAt", ascending: false),
                    NSSortDescriptor(key: "startDate", ascending: false)
                ]
            )
            .map { entities in
                let cycles = entities.map { $0.toDomain() }
                guard !cycles.isEmpty else { return nil }
                
                let now = Date()
                let cal = Calendar.current
                
                // 1) 진행 중(오늘 포함) 사이클 우선
                if let ongoing = cycles.first(where: { cycle in
                    let start = cycle.startDate
                    let totalDays: Int = {
                        if let mirrorVal = Mirror(reflecting: cycle).children.first(where: { $0.label == "totalDays" })?.value as? Int {
                            return mirrorVal
                        } else {
                            return cycle.activeDays + cycle.breakDays
                        }
                    }()
                    let end = cal.date(byAdding: .day, value: max(totalDays - 1, 0), to: start) ?? start
                    return (start ... end).contains(now)
                }) {
                    return ongoing
                }
                
                // 2) 없으면 createdAt 최신 반환
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
            let fetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: "PillCycleEntity")
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
            
            let context = self.coreDataManager.viewContext
            
            // 사이클 찾기
            let cycleFetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: "PillCycleEntity")
            cycleFetchRequest.predicate = NSPredicate(format: "id == %@", cycleID as CVarArg)
            
            do {
                guard let PillCycleEntity = try context.fetch(cycleFetchRequest).first else {
                    observer.onError(CoreDataError.invalidData)
                    return Disposables.create()
                }
                
                // 레코드 찾기
                let recordFetchRequest: NSFetchRequest<PillRecordEntity> = NSFetchRequest(entityName: "PillRecordEntity")
                recordFetchRequest.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)
                
                if let recordEntity = try context.fetch(recordFetchRequest).first {
                    // 업데이트
                    recordEntity.update(from: record)
                } else {
                    // 새로 생성
                    let newRecordEntity = PillRecordEntity.from(domain: record, context: context)
                    newRecordEntity.cycle = PillCycleEntity
                }
                
                try context.save()
                
                // ⭐️ 위젯 업데이트
                WidgetCenter.shared.reloadAllTimelines()
                print("💊 복용 기록 업데이트 완료 - 위젯 업데이트")
                
                observer.onNext(())
                observer.onCompleted()
            } catch {
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
