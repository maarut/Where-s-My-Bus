//
//  Array+Utils.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 26/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation

extension Array
{
    func first(@noescape predicate: (Element) -> Bool) -> Element?
    {
        for element in self { if predicate(element) { return element } }
        return nil
    }
}