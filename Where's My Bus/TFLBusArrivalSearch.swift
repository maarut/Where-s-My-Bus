//
//  TFLBusArrivalSearch.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 05/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation
// MARK: - TFLBusArrivalSearchResultsProcessor Protocol
protocol TFLBusArrivalSearchResultsProcessor: class
{
    func processResults(arrivals: [BusArrival])
    func handleError(error: NSError)
}

// MARK: - TFLBusArrivalSearchError Enum
enum TFLBusArrivalSearchError: Int
{
    case JsonParse
    case NoData
}

// MARK: - TFLBusArrivalSearch class
class TFLBusArrivalSearch: TFLNetworkOperationProcessor, TFLNetworkOperationRequestor
{
    private weak var resultsHandler: TFLBusArrivalSearchResultsProcessor?
    private let _request: NSURLRequest
    var request: NSURLRequest {
        get {
            return _request
        }
    }
    
    init(stationId: NaptanId, resultsHandler: TFLBusArrivalSearchResultsProcessor)
    {
        let method = "StopPoint/\(stationId)/Arrivals"
        _request = NSURLRequest(URL: TFLURL(method: method, parameters: [:]).url)
        self.resultsHandler = resultsHandler
    }
    
    func processData(data: NSData)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [[String: AnyObject]] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "TFLBusStopSearch.processData",
                                code: TFLBusArrivalSearchError.JsonParse.rawValue, userInfo: userInfo)
            handleError(error)
            return
        }
        let arrivals = parseArrivals(json)
        resultsHandler?.processResults(arrivals.sort { $0.ETA < $1.ETA })
    }
    
    func handleError(error: NSError)
    {
        resultsHandler?.handleError(error)
    }
}

// MARK: - TFLBusArrivalSearch Private Functions
private extension TFLBusArrivalSearch
{
    func parseArrivals(data: [[String: AnyObject]]) -> [BusArrival]
    {
        do {
            return try data.flatMap { try BusArrival(json: $0) }
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "JSON response could not be parsed.",
                            NSUnderlyingErrorKey: error]
            let error = NSError(domain: "TFLBusArrivalSearch.parseArrivals",
                                code: TFLBusArrivalSearchError.JsonParse.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return []
    }
    
    func parseJson(data: NSData) -> AnyObject?
    {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object", NSUnderlyingErrorKey: error]
            let error = NSError(domain: "TFLBusArrivalSearch.parseJson",
                                code: TFLBusArrivalSearchError.NoData.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return nil
    }
}