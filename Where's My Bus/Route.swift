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
    convenience init(line: Line, context: NSManagedObjectContext)
    {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Route", in: context)!,
                  insertInto: context)
        self.lineId = line.id
        self.lineName = line.name
        self.isHidden = NSNumber(value: false as Bool)
    }
}
