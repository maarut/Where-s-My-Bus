//
//  Route.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 24/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation
import CoreData

class Route: NSManagedObject
{    
    // Insert code here to add functionality to your managed object subclass
    convenience init(lineId: LineId, context: NSManagedObjectContext)
    {
        self.init(entity: NSEntityDescription.entityForName("Route", inManagedObjectContext: context)!,
                  insertIntoManagedObjectContext: context)
        self.lineId = lineId
    }
}