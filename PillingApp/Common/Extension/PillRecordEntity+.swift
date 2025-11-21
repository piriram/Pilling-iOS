//
//  PillRecordEntity+Extension.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/13/25.
//

import CoreData

// MARK: - Domain Model Conversion

extension PillRecordEntity {
    
    func toDomain() -> DayRecord {
        let pillStatus = PillStatus(rawValue: Int(status)) ?? .scheduled

        // 🔍 [디버깅] Entity -> Domain 변환
        let memoValue = memo ?? ""
        print("🔍 [PillRecordEntity] toDomain 변환")
        print("   📝 Entity.memo: '\(memo ?? "nil")'")
        print("   📦 변환된 DayRecord.memo: '\(memoValue)'")

        return DayRecord(
            id: id ?? UUID(),
            cycleDay: Int(cycleDay),
            status: pillStatus,
            scheduledDateTime: scheduledDateTime ?? Date(),
            takenAt: takenAt,
            memo: memoValue,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
    
    static func from(
        domain: DayRecord,
        context: NSManagedObjectContext
    ) -> PillRecordEntity {
        // 🔍 [디버깅] Domain -> Entity 생성
        print("🔍 [PillRecordEntity] from Domain 생성")
        print("   📝 domain.memo: '\(domain.memo)'")

        let entity = PillRecordEntity(context: context)
        entity.id = domain.id
        entity.cycleDay = Int16(domain.cycleDay)
        entity.status = Int16(domain.status.rawValue)
        entity.scheduledDateTime = domain.scheduledDateTime
        entity.takenAt = domain.takenAt
        entity.memo = domain.memo
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt

        print("   💾 Entity.memo: '\(entity.memo ?? "nil")'")

        return entity
    }
    
    func update(from domain: DayRecord) {
        // 🔍 [디버깅] Entity 업데이트
        print("🔍 [PillRecordEntity] update 호출")
        print("   📝 업데이트 전 Entity.memo: '\(memo ?? "nil")'")
        print("   📦 domain.memo: '\(domain.memo)'")

        cycleDay = Int16(domain.cycleDay)
        status = Int16(domain.status.rawValue)
        scheduledDateTime = domain.scheduledDateTime
        takenAt = domain.takenAt
        memo = domain.memo
        updatedAt = domain.updatedAt

        print("   💾 업데이트 후 Entity.memo: '\(memo ?? "nil")'")
    }
}

