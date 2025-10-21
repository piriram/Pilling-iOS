//
//  SharedCoreDataManager.swift
//  DaillyWidgetExtension
//
//  Created by 잠만보김쥬디 on 10/17/25.
//

import CoreData
import Foundation

// MARK: - SharedCoreDataManager

final class SharedCoreDataManager {
    static let shared = SharedCoreDataManager()
    
    private let appGroupIdentifier = "group.app.Pilltastic.Pilling"
    
    private init() {}
    
    // MARK: - Core Data Stack
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PillingApp")
        
        // App Group을 위한 URL 설정
        if let storeURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )?.appendingPathComponent("PillingApp.sqlite") {
            let description = NSPersistentStoreDescription(url: storeURL)
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            container.persistentStoreDescriptions = [description]
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Fetch Methods
    
    func fetchCurrentCycle(timeProvider: TimeProvider = SystemTimeProvider()) -> PillCycle? {
        let fetchRequest: NSFetchRequest<PillCycleEntity> = PillCycleEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "startDate", ascending: false)
        ]
        
        do {
            let entities = try viewContext.fetch(fetchRequest)
            let cycles = entities.map { $0.toDomain() }
            
            guard !cycles.isEmpty else { return nil }
            
            let now = timeProvider.now
            let cal = timeProvider.calendar
            
            if let ongoing = cycles.first(where: { cycle in
                let start = cycle.startDate
                let total = cycle.activeDays + cycle.breakDays
                let startOfStart = timeProvider.startOfDay(for: start)
                guard let endStart = cal.date(byAdding: .day, value: total - 1, to: startOfStart) else { return false }
                // 필요하면 하루 끝(23:59:59)까지 포함
                let end = cal.date(byAdding: .second, value: 86399, to: endStart) ?? endStart
                return (startOfStart...end).contains(now)
            }) {
                return ongoing
            }
            return cycles.first
        } catch {
            print("Failed to fetch current cycle: \(error)")
            return nil
        }
    }
}
