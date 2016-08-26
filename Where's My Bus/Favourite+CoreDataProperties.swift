//
//  Favourite+CoreDataProperties.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 26/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Favourite {

    @NSManaged var stationId: String?
    @NSManaged var sortOrder: NSNumber?
    @NSManaged var stopName: String?
    @NSManaged var stopLetter: String?
    @NSManaged var routes: NSSet?

}
