//
//  Favourite.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 11/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation
import CoreData


class Favourite: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    convenience init(naptanId: NaptanId, context: NSManagedObjectContext)
    {
        self.init(entity: NSEntityDescription.entityForName("Favourite", inManagedObjectContext: context)!,
            insertIntoManagedObjectContext: context)
        self.naptanId = naptanId
    }
}
