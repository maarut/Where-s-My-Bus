//
//  Dispatch+Utils.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 04/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation

enum DispatchQueueType
{
    case Serial
    case Concurrent
}

class Dispatch {
    static let mainQueue = Dispatch()
    let queue: dispatch_queue_t
    
    private init()
    {
        queue = dispatch_get_main_queue()
    }
    
    init(label: String, type: DispatchQueueType)
    {
        switch type {
        case .Concurrent:
            queue = dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT)
            break
        case .Serial:
            queue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL)
            break
        }
    }
    
    func async(block: () -> Void)
    {
        dispatch_async(queue, block)
    }
    
    func sync(block: () -> Void)
    {
        dispatch_sync(queue, block)
    }
}