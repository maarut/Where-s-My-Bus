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
    convenience init(stopPoint: StopPoint, context: NSManagedObjectContext)
    {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Favourite", in: context)!,
            insertInto: context)
        self.stationId = stopPoint.id
        self.stopLetter = stopPoint.stopLetter
        self.stopName = stopPoint.name
        let mutableRoutes = self.routes?.mutableCopy()
        for line in stopPoint.lines {
            let route = Route(line: line, context: context)
            route.favourite = self
            (mutableRoutes as AnyObject).add(route)
        }
    }
}
