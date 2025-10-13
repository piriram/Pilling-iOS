//
//  CoreDataPillCycleRepository.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import CoreData
import RxSwift

// MARK: - CoreDataPillCycleRepository

final class CoreDataPillCycleRepository: PillCycleRepositoryProtocol {
    
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - PillCycleRepositoryProtocol
    
    func fetchCurrentCycle() -> Observable<PillCycle?> {
        return coreDataManager
            .fetch(
                entityType: PillCycleEntity.self,
                sortDescriptors: [NSSortDescriptor(key: "startDate", ascending: false)]
            )
            .map { entities in
                return entities.first?.toDomain()
            }
    }
    
    func saveCycle(_ cycle: PillCycle) -> Observable<Void> {
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
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.saveFailed(error))
            }
            
            return Disposables.create()
        }
    }
    
    func updateRecord(_ record: PillRecord, in cycleID: UUID) -> Observable<Void> {
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
                guard let cycleEntity = try context.fetch(cycleFetchRequest).first else {
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
                    newRecordEntity.cycle = cycleEntity
                }
                
                try context.save()
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
    }
    
    func fetchAllCycles() -> Observable<[PillCycle]> {
        return coreDataManager
            .fetch(
                entityType: PillCycleEntity.self,
                sortDescriptors: [NSSortDescriptor(key: "startDate", ascending: false)]
            )
            .map { entities in
                return entities.map { $0.toDomain() }
            }
    }
}
