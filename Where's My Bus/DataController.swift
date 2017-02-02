//
//  DataController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 25/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation
import CoreData

class DataController
{
    fileprivate let model: NSManagedObjectModel
    fileprivate let coordinator: NSPersistentStoreCoordinator
    fileprivate let dbURL: URL
    fileprivate let persistingContext: NSManagedObjectContext
    
    let mainThreadContext: NSManagedObjectContext
    
    init?(withModelName modelName: String)
    {
        guard let modelUrl = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            NSLog("Unable to find model in bundle")
            return nil
        }
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            NSLog("Unable to create object model")
            return nil
        }
        guard let docsDir = FileManager.default.urls(for: .documentDirectory,
            in: .userDomainMask).first else {
            NSLog("Unable to obtain Documents directory for user")
            return nil
        }
        self.model = model
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        dbURL = docsDir.appendingPathComponent("\(modelName).sqlite")
        
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.name = "Persisting"
        persistingContext.persistentStoreCoordinator = coordinator
        
        mainThreadContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainThreadContext.name = "Main"
        mainThreadContext.parent = persistingContext
        
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL,
                options: options)
        }
        catch let error as NSError {
            logErrorAndAbort(error)
        }
    }
    
    func save()
    {
        mainThreadContext.performAndWait {
            if self.mainThreadContext.hasChanges {
                do { try self.mainThreadContext.save() }
                catch let error as NSError { logErrorAndAbort(error) }
            }
        }
        persistingContext.perform {
            if self.persistingContext.hasChanges {
                do { try self.persistingContext.save() }
                catch let error as NSError { logErrorAndAbort(error) }
            }
        }
    }
    
    func unfavourite(_ stationId: NaptanId)
    {
        mainThreadContext.perform {
            if let fav = self.retrieve(stationId) {
                self.mainThreadContext.delete(fav)
                self.save()
            }
        }
    }
    
    func favourite(_ stopPoint: StopPoint)
    {
        mainThreadContext.perform {
            if self.retrieve(stopPoint.id) == nil {
                let favourites = self.allFavourites()
                do { try favourites.performFetch() }
                catch let error as NSError { logErrorAndAbort(error) }
                let favourite = Favourite(stopPoint: stopPoint, context: self.mainThreadContext)
                favourite.sortOrder = favourites.fetchedObjects?.count as NSNumber?? ?? Int.max as NSNumber?
                self.save()
            }
        }
    }
    
    func isFavourite(_ stationId: NaptanId) -> Bool
    {
        var isFavourite = false
        mainThreadContext.performAndWait {
            isFavourite = self.retrieve(stationId) != nil
        }
        return isFavourite
    }
    
    func toggleHiddenLine(_ line: Line, for favourite: Favourite)
    {
        favourite.managedObjectContext?.perform {
            if let route = favourite.routes?.allObjects.first( { ($0 as! Route).lineId == line.id } ) as? Route {
                route.isHidden = NSNumber(value: !route.isHidden!.boolValue as Bool)
            }
            self.save()
        }
    }
    
    func allFavourites() -> NSFetchedResultsController<Favourite>
    {
        let request = NSFetchRequest<Favourite>(entityName: "Favourite")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        return NSFetchedResultsController<Favourite>(fetchRequest: request, managedObjectContext: mainThreadContext,
            sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func retrieve(_ stationId: NaptanId) -> Favourite?
    {
        let fetchRequest = NSFetchRequest<Favourite>(entityName: "Favourite")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "stationId", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "stationId == %@", stationId)
        do {
            let results = try self.mainThreadContext.fetch(fetchRequest)
            return results.first
        }
        catch let error as NSError {
            logErrorAndAbort(error)
        }
        return nil
    }
}

private func logErrorAndAbort(_ error: NSError)
{
    var errorString = "Core Data Error: \(error.localizedDescription)\n\(error)\n"
    if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
        detailedErrors.forEach { errorString += "\($0.localizedDescription)\n\($0)\n" }
    }
    fatalError(errorString)
}
