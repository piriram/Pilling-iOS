//
//  CoreDataManager.swift
//  PillingApp
//
//  Created by 잠만보김쥬디 on 10/12/25.
//

import CoreData
import RxSwift

// MARK: - CoreDataManager

final class CoreDataManager {
    static let shared = CoreDataManager()
    
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
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - CRUD Operations
    
    func save() -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.viewContext
            
            guard context.hasChanges else {
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                try context.save()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.saveFailed(error))
            }
            
            return Disposables.create()
        }
    }
    
    func fetch<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> Observable<[T]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.viewContext
            let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entityType))
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = sortDescriptors
            
            do {
                let results = try context.fetch(fetchRequest)
                observer.onNext(results)
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.fetchFailed(error))
            }
            
            return Disposables.create()
        }
    }
    
    func delete<T: NSManagedObject>(_ object: T) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.viewContext
            context.delete(object)
            
            do {
                try context.save()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.deleteFailed(error))
            }
            
            return Disposables.create()
        }
    }
    
    func deleteAll<T: NSManagedObject>(entityType: T.Type) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                try context.save()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.deleteFailed(error))
            }
            
            return Disposables.create()
        }
    }
}

// MARK: - CoreDataError

enum CoreDataError: Error {
    case contextNotAvailable
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidData
}
