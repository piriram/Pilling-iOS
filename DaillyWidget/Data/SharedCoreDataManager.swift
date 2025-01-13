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
    
    func fetchCurrentCycle() -> Cycle? {
        let fetchRequest: NSFetchRequest<PillCycleEntity> = PillCycleEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false),
            NSSortDescriptor(key: "startDate", ascending: false)
        ]
        
        do {
            let entities = try viewContext.fetch(fetchRequest)
            let cycles = entities.map { $0.toDomain() }
            
            guard !cycles.isEmpty else { return nil }
            
            let now = Date()
            let calendar = Calendar.current
            
            // 진행 중인 사이클 찾기
            if let ongoingCycle = cycles.first(where: { cycle in
                let start = cycle.startDate
                let totalDays = cycle.activeDays + cycle.breakDays
                guard let end = calendar.date(byAdding: .day, value: totalDays - 1, to: start) else {
                    return false
                }
                return (start...end).contains(now)
            }) {
                return ongoingCycle
            }
            
            // 진행 중인 사이클이 없으면 가장 최신 사이클 반환
            return cycles.first
        } catch {
            print("Failed to fetch current cycle: \(error)")
            return nil
        }
    }
}
