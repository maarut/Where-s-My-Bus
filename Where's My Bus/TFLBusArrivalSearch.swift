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
    func processResults(_ arrivals: [BusArrival])
    func handleError(_ error: NSError)
}

// MARK: - TFLBusArrivalSearchError Enum
enum TFLBusArrivalSearchError: Int
{
    case jsonParse
    case noData
}

// MARK: - TFLBusArrivalSearch class
class TFLBusArrivalSearch: TFLNetworkOperationProcessor, TFLNetworkOperationRequestor
{
    fileprivate weak var resultsHandler: TFLBusArrivalSearchResultsProcessor?
    fileprivate let _request: URLRequest
    var request: URLRequest {
        get {
            return _request
        }
    }
    
    init(stationId: NaptanId, resultsHandler: TFLBusArrivalSearchResultsProcessor)
    {
        let method = "StopPoint/\(stationId)/Arrivals"
        _request = URLRequest(url: TFLURL(method: method, parameters: [:]).url as URL)
        self.resultsHandler = resultsHandler
    }
    
    func processData(_ data: Data)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [[String: AnyObject]] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "TFLBusStopSearch.processData",
                                code: TFLBusArrivalSearchError.jsonParse.rawValue, userInfo: userInfo)
            handleError(error)
            return
        }
        let arrivals = parseArrivals(json)
        resultsHandler?.processResults(arrivals.sorted { $0.ETA < $1.ETA })
    }
    
    func handleError(_ error: NSError)
    {
        resultsHandler?.handleError(error)
    }
}

// MARK: - TFLBusArrivalSearch Private Functions
private extension TFLBusArrivalSearch
{
    func parseArrivals(_ data: [[String: AnyObject]]) -> [BusArrival]
    {
        do {
            return try data.flatMap { try BusArrival(json: $0) }
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "JSON response could not be parsed.",
                            NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "TFLBusArrivalSearch.parseArrivals",
                                code: TFLBusArrivalSearchError.jsonParse.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return []
    }
    
    func parseJson(_ data: Data) -> Any?
    {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object", NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "TFLBusArrivalSearch.parseJson",
                                code: TFLBusArrivalSearchError.noData.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return nil
    }
}
