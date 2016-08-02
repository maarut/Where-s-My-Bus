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
    
    func busStopSearch(searchCriteria: TFLBusStopSearchCriteria, resultsProcessor: TFLBusStopSearchResultsProcessor,
        errorHandler: (NSError) -> Void)
    {
        let busStopSearch = TFLBusStopSearch(searchCriteria: searchCriteria, resultsHandler: resultsProcessor,
            errorHandler: errorHandler)
        let networkOp = TFLNetworkOperation(processor: busStopSearch, requestor: busStopSearch)
        networkOperationQueue.addOperation(networkOp)
    }
}
