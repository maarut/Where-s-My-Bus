//
//  TFLBusStopDetails.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 12/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation
// MARK: - TFLBusStopDetailsProcessor Protocol
protocol TFLBusStopDetailsProcessor: class
{
    func processStopPoint(stopPoint: StopPoint)
    func handleError(error: NSError)
}

// MARK: - TFLBusStopDetailsError Enum
enum TFLBusStopDetailsError: Int
{
    case JsonParse
    case NoData
}

// MARK: - TFLBusStopDetails class
class TFLBusStopDetails: TFLNetworkOperationProcessor, TFLNetworkOperationRequestor
{
    private weak var resultsHandler: TFLBusStopDetailsProcessor?
    private let stationId: NaptanId
    private let _request: NSURLRequest
    var request: NSURLRequest {
        get {
            return _request
        }
    }
    
    init(stationId: NaptanId, resultsHandler: TFLBusStopDetailsProcessor)
    {
        let method = "StopPoint/\(stationId)"
        _request = NSURLRequest(URL: TFLURL(method: method, parameters: [:]).url)
        self.resultsHandler = resultsHandler
        self.stationId = stationId
    }
    
    func processData(data: NSData)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "TFLBusStopDetails.processData",
                                code: TFLBusStopDetailsError.JsonParse.rawValue, userInfo: userInfo)
            handleError(error)
            return
        }
        if let stopPoint = parseDetails(json) {
            if stopPoint.id == stationId { resultsHandler?.processStopPoint(stopPoint) }
            else {
                for child in stopPoint.children {
                    if child.id == stationId {
                        resultsHandler?.processStopPoint(child)
                        break
                    }
                }
            }
        }
    }
    
    func handleError(error: NSError)
    {
        resultsHandler?.handleError(error)
    }
}

// MARK: - TFLBusStopDetails Private Functions
private extension TFLBusStopDetails
{
    func parseDetails(json: [String: AnyObject]) -> StopPoint?
    {
        do {
            return try StopPoint(json: json)
        }
        catch let error as NSError {
            if error.code == StopPointError.StopLetterKeyNotFound.rawValue {
                return parseChildren(json).filter { $0.id == stationId }.first
            }
            processError(error)
        }
        return nil
    }
    
    func parseChildren(json: [String: AnyObject]) -> [StopPoint]
    {
        if let children = json[StopPoint.ChildrenKey] as? [[String: AnyObject]] {
            do {
                return try children.flatMap { try StopPoint(json: $0) }
            }
            catch let error as NSError {
                processError(error)
            }
        }
        return []
    }
    
    func processError(underlyingError: NSError)
    {
        let userInfo = [NSLocalizedDescriptionKey: "JSON response could not be parsed.",
                        NSUnderlyingErrorKey: underlyingError]
        let error = NSError(domain: "TFLBusArrivalSearch.parseArrivals",
                            code: TFLBusStopDetailsError.JsonParse.rawValue, userInfo: userInfo)
        handleError(error)
    }
    
    func parseJson(data: NSData) -> AnyObject?
    {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object", NSUnderlyingErrorKey: error]
            let error = NSError(domain: "TFLBusArrivalSearch.parseJson",
                                code: TFLBusStopDetailsError.NoData.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return nil
    }
}