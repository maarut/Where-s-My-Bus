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
        performOperation(busStopSearch, requestor: busStopSearch)
        
    }
    
    func busArrivalTimesForStop(stop: NaptanId, resultsProcessor: TFLBusArrivalSearchResultsProcessor)
    {
        let busArrivalSearch = TFLBusArrivalSearch(stationId: stop, resultsHandler: resultsProcessor)
        performOperation(busArrivalSearch, requestor: busArrivalSearch)
        
    }
    
    func detailsForBusStop(stationId: NaptanId, resultsProcessor: TFLBusStopDetailsProcessor)
    {
        let detailsSearch = TFLBusStopDetails(stationId: stationId, resultsHandler: resultsProcessor)
        performOperation(detailsSearch, requestor: detailsSearch)
        
    }
    
    private func performOperation(operation: TFLNetworkOperationProcessor, requestor: TFLNetworkOperationRequestor)
    {
        let networkOp = TFLNetworkOperation(processor: operation, requestor: requestor)
        networkOperationQueue.addOperation(networkOp)
    }
}
