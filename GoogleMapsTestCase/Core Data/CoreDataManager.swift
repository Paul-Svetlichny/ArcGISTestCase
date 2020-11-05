//
//  CoreDataManager.swift
//  GoogleMapsTestCase
//
//  Created by Paul Svetlichny on 18.10.2020.
//

import CoreData

// MARK: - Core Data stack
class CoreDataManager {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GoogleMapsTestCase")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        context.mergePolicy = NSRollbackMergePolicy
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func removeAll() {
        let fetchRequest: NSFetchRequest<FoodPlace> = FoodPlace.fetchRequest()
        let context = persistentContainer.viewContext

        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                context.delete(object)
            }
            saveContext()
        } catch let error as NSError {
            // error handling
        }
    }

    func removeAll(excluding name: String?) {
        let fetchRequest: NSFetchRequest<FoodPlace> = FoodPlace.fetchRequest()
        let context = persistentContainer.viewContext

        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects where object.name != name {
                context.delete(object)
            }
            saveContext()
        } catch let error as NSError {
            // error handling
        }
    }

    func initialData() -> [FoodPlace]? {
        let context = persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<FoodPlace> = FoodPlace.fetchRequest()
        
        do {
            return try context.fetch(fetchRequest)
        } catch let error as NSError {
            // error handling
            return nil
        }
    }
    
    func place(with name: String?) -> FoodPlace? {
        guard let name = name else {
            return nil
        }
        
        let context = persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<FoodPlace> = FoodPlace.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name LIKE %@", name)
        
        do {
            return try context.fetch(fetchRequest).first
        } catch let error as NSError {
            // error handling
            return nil
        }
    }
}
