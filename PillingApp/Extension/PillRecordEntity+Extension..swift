//
//  PillRecordEntity+Extension.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import CoreData

// MARK: - Domain Model Conversion

extension PillRecordEntity {
    
    func toDomain() -> PillRecord {
        let pillStatus = PillStatus(rawValue: Int(status)) ?? .scheduled
        
        return PillRecord(
            id: id ?? UUID(),
            cycleDay: Int(cycleDay),
            status: pillStatus,
            scheduledDateTime: scheduledDateTime ?? Date(),
            takenAt: takenAt,
            memo: memo ?? "",
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    static func from(
        domain: PillRecord,
        context: NSManagedObjectContext
    ) -> PillRecordEntity {
        let entity = PillRecordEntity(context: context)
        entity.id = domain.id
        entity.cycleDay = Int16(domain.cycleDay)
        entity.status = Int16(domain.status.rawValue)
        entity.scheduledDateTime = domain.scheduledDateTime
        entity.takenAt = domain.takenAt
        entity.memo = domain.memo
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt
        return entity
    }
    
    func update(from domain: PillRecord) {
        cycleDay = Int16(domain.cycleDay)
        status = Int16(domain.status.rawValue)
        scheduledDateTime = domain.scheduledDateTime
        takenAt = domain.takenAt
        memo = domain.memo
        updatedAt = domain.updatedAt
    }
}

