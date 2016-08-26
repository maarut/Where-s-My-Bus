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
    
    func unfavourite(stationId: NaptanId)
    {
        mainThreadContext.performBlock {
            if let fav = self.retrieve(stationId) {
                self.mainThreadContext.deleteObject(fav)
                self.save()
            }
        }
    }
    
    func favourite(stopPoint: StopPoint)
    {
        mainThreadContext.performBlock {
            if self.retrieve(stopPoint.id) == nil {
                let favourites = self.allFavourites()
                do { try favourites.performFetch() }
                catch let error as NSError { logErrorAndAbort(error) }
                let favourite = Favourite(stopPoint: stopPoint, context: self.mainThreadContext)
                favourite.sortOrder = favourites.fetchedObjects?.count ?? Int.max
                self.save()
            }
        }
    }
    
    func isFavourite(stationId: NaptanId) -> Bool
    {
        var isFavourite = false
        mainThreadContext.performBlockAndWait {
            isFavourite = self.retrieve(stationId) != nil
        }
        return isFavourite
    }
    
    func toggleHiddenLine(line: Line, for favourite: Favourite)
    {
        favourite.managedObjectContext?.performBlock {
            if let route = favourite.routes?.allObjects.first( { ($0 as! Route).lineId == line.id } ) as? Route {
                route.isHidden = NSNumber(bool: !route.isHidden!.boolValue)
            }
            self.save()
        }
    }
    
    func allFavourites() -> NSFetchedResultsController
    {
        let request = NSFetchRequest(entityName: "Favourite")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: mainThreadContext,
            sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func retrieve(stationId: NaptanId) -> Favourite?
    {
        let fetchRequest = NSFetchRequest(entityName: "Favourite")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "stationId", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "stationId == %@", stationId)
        do {
            let results = try self.mainThreadContext.executeFetchRequest(fetchRequest)
            return results.first as? Favourite
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
