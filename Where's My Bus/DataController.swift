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
    private let model: NSManagedObjectModel
    private let coordinator: NSPersistentStoreCoordinator
    private let dbURL: NSURL
    private let persistingContext: NSManagedObjectContext
    
    let mainThreadContext: NSManagedObjectContext
    
    init?(withModelName modelName: String)
    {
        guard let modelUrl = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") else {
            NSLog("Unable to find model in bundle")
            return nil
        }
        guard let model = NSManagedObjectModel(contentsOfURL: modelUrl) else {
            NSLog("Unable to create object model")
            return nil
        }
        guard let docsDir = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory,
            inDomains: .UserDomainMask).first else {
            NSLog("Unable to obtain Documents directory for user")
            return nil
        }
        self.model = model
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        dbURL = docsDir.URLByAppendingPathComponent("\(modelName).sqlite")
        
        persistingContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        persistingContext.name = "Persisting"
        persistingContext.persistentStoreCoordinator = coordinator
        
        mainThreadContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        mainThreadContext.name = "Main"
        mainThreadContext.parentContext = persistingContext
        
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: dbURL,
                options: options)
        }
        catch let error as NSError {
            logErrorAndAbort(error)
        }
    }
    
    func save()
    {
        mainThreadContext.performBlockAndWait {
            if self.mainThreadContext.hasChanges {
                do { try self.mainThreadContext.save() }
                catch let error as NSError { logErrorAndAbort(error) }
            }
        }
        persistingContext.performBlock {
            if self.persistingContext.hasChanges {
                do { try self.persistingContext.save() }
                catch let error as NSError { logErrorAndAbort(error) }
            }
        }
    }
    
    func unfavourite(naptanId: NaptanId)
    {
        mainThreadContext.performBlock {
            if let fav = self.retrieve(naptanId) {
                self.mainThreadContext.deleteObject(fav)
                self.save()
            }
        }
    }
    
    func favourite(naptanId: NaptanId)
    {
        mainThreadContext.performBlock {
            if self.retrieve(naptanId) == nil {
                let favourites = self.allFavourites()
                do { try favourites.performFetch() }
                catch let error as NSError { logErrorAndAbort(error) }
                let favourite = Favourite(naptanId: naptanId, context: self.mainThreadContext)
                favourite.sortOrder = favourites.fetchedObjects?.count ?? Int.max
                self.save()
            }
        }
    }
    
    func isFavourite(naptanId: NaptanId) -> Bool
    {
        var isFavourite = false
        mainThreadContext.performBlockAndWait {
            isFavourite = self.retrieve(naptanId) != nil
        }
        return isFavourite
    }
    
    func addHiddenRoute(lineId: LineId, to favourite: Favourite)
    {
        favourite.managedObjectContext?.performBlock {
            let route: Route
            if let r = self.retrieveLineId(lineId) {
                route = r
            }
            else {
                route = Route(lineId: lineId, context: favourite.managedObjectContext!)
            }
            route.mutableSetValueForKey("favourites").addObject(favourite)
            self.save()
        }
    }
    
    func removeHiddenRoute(lineId: LineId, from favourite: Favourite)
    {
        favourite.managedObjectContext?.performBlock {
            if let route = favourite.hiddenRoutes?.filter( { ($0 as! Route).lineId == lineId } ).first as? Route {
                route.mutableSetValueForKey("favourites").removeObject(favourite)
                self.save()
            }
        }
    }
    
    func allFavourites() -> NSFetchedResultsController
    {
        let request = NSFetchRequest(entityName: "Favourite")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: mainThreadContext,
            sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func retrieve(naptanId: NaptanId) -> Favourite?
    {
        let fetchRequest = NSFetchRequest(entityName: "Favourite")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "naptanId", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "naptanId == %@", naptanId)
        do {
            let results = try self.mainThreadContext.executeFetchRequest(fetchRequest)
            return results.first as? Favourite
        }
        catch let error as NSError {
            logErrorAndAbort(error)
        }
        return nil
    }
    
    private func retrieveLineId(lineId: LineId) -> Route?
    {
        let fetchRequest = NSFetchRequest(entityName: "Route")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lineId", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "lineId == %@", lineId)
        do {
            let results = try self.mainThreadContext.executeFetchRequest(fetchRequest)
            return results.first as? Route
        }
        catch let error as NSError {
            logErrorAndAbort(error)
        }
        return nil
    }
}

private func logErrorAndAbort(error: NSError)
{
    var errorString = "Core Data Error: \(error.localizedDescription)\n\(error)\n"
    if let detailedErrors = error.userInfo[NSDetailedErrorsKey] as? [NSError] {
        detailedErrors.forEach { errorString += "\($0.localizedDescription)\n\($0)\n" }
    }
    fatalError(errorString)
}
