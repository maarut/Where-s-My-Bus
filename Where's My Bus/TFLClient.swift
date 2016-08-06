//
//  TFLClient.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 01/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation

class TFLClient {
    private let networkOperationQueue = NSOperationQueue()
    
    static let instance = TFLClient()
    
    private init() { }
    
    func busStopSearch(searchCriteria: TFLBusStopSearchCriteria, resultsProcessor: TFLBusStopSearchResultsProcessor)
    {
        let busStopSearch = TFLBusStopSearch(searchCriteria: searchCriteria, resultsHandler: resultsProcessor)
        let networkOp = TFLNetworkOperation(processor: busStopSearch, requestor: busStopSearch)
        networkOperationQueue.addOperation(networkOp)
    }
    
    func busArrivalTimesForStop(stop: NaptanId, resultsProcessor: TFLBusArrivalSearchResultsProcessor)
    {
        let busArrivalSearch = TFLBusArrivalSearch(stationId: stop, resultsHandler: resultsProcessor)
        let networkOp = TFLNetworkOperation(processor: busArrivalSearch, requestor: busArrivalSearch)
        networkOperationQueue.addOperation(networkOp)
    }
}
