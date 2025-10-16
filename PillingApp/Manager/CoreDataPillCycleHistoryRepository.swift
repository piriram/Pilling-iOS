//
//  CoreDataPillCycleHistoryRepository.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/16/25.
//

import UIKit
import RxSwift
import RxCocoa
import CoreData

// MARK: - Repository
protocol PillCycleHistoryRepository {
    func fetchAllCycles() throws -> [PillCycle]
}

final class CoreDataPillCycleHistoryRepository: PillCycleHistoryRepository {
    private let context: NSManagedObjectContext?
    init(context: NSManagedObjectContext?) { self.context = context }
    
    func fetchAllCycles() throws -> [PillCycle] {
        guard let ctx = context else { return [] }
        let request = NSFetchRequest<NSManagedObject>(entityName: "PillCycleEntity")
        let sortCreated = NSSortDescriptor(key: "createdAt", ascending: false)
        let sortStart = NSSortDescriptor(key: "startDate", ascending: false)
        request.sortDescriptors = [sortCreated, sortStart]
        
        let objects = try ctx.fetch(request)
        var result: [PillCycle] = []
        result.reserveCapacity(objects.count)
        for obj in objects {
            let id = (obj.value(forKey: "id") as? UUID) ?? UUID()
            let cycleNumber = (obj.value(forKey: "cycleNumber") as? Int) ?? 0
            let startDate = (obj.value(forKey: "startDate") as? Date) ?? Date()
            let activeDays = (obj.value(forKey: "activeDays") as? Int) ?? 21
            let breakDays = (obj.value(forKey: "breakDays") as? Int) ?? 7
            let scheduledTime = (obj.value(forKey: "scheduledTime") as? String) ?? "09:00"
            let createdAt = (obj.value(forKey: "createdAt") as? Date) ?? startDate
            let records = (obj.value(forKey: "records") as? [PillRecord]) ?? []
            let cycle = PillCycle(
                id: id,
                cycleNumber: cycleNumber,
                startDate: startDate,
                activeDays: activeDays,
                breakDays: breakDays,
                scheduledTime: scheduledTime,
                records: records,
                createdAt: createdAt
            )
            result.append(cycle)
        }
        return result
    }
}
