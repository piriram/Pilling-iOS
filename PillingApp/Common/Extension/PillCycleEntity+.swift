//
//  PillCycleEntity+Extension.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import CoreData

// MARK: - Convenience

extension PillCycleEntity {
    
    var recordsArray: [PillRecordEntity] {
        let set = records as? Set<PillRecordEntity> ?? []
        return set.sorted { $0.cycleDay < $1.cycleDay }
    }
}

// MARK: - Domain Model Conversion

extension PillCycleEntity {
    
    func toDomain() -> PillCycle {
        let domainRecords = recordsArray.map { $0.toDomain() }
        
        return PillCycle(
            id: id ?? UUID(),
            cycleNumber: Int(cycleNumber),
            startDate: startDate ?? Date(),
            activeDays: Int(activeDays),
            breakDays: Int(breakDays),
            scheduledTime: scheduledTime ?? "09:00",
            records: domainRecords,
            createdAt: (self.createdAt ?? self.startDate) ?? Date()
        )
    }
    
    static func from(
        domain: PillCycle,
        context: NSManagedObjectContext
    ) -> PillCycleEntity {
        let entity = PillCycleEntity(context: context)
        entity.id = domain.id
        entity.cycleNumber = Int16(domain.cycleNumber)
        entity.startDate = domain.startDate
        entity.activeDays = Int16(domain.activeDays)
        entity.breakDays = Int16(domain.breakDays)
        entity.scheduledTime = domain.scheduledTime
        entity.createdAt = Date()
        
        domain.records.forEach { record in
            let recordEntity = PillRecordEntity.from(domain: record, context: context)
            recordEntity.cycle = entity
        }
        
        return entity
    }
    
    func update(from domain: PillCycle) {
        cycleNumber = Int16(domain.cycleNumber)
        startDate = domain.startDate
        activeDays = Int16(domain.activeDays)
        breakDays = Int16(domain.breakDays)
        scheduledTime = domain.scheduledTime
    }
}

