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
    func process(stopPoint: StopPoint)
    func handle(error: NSError)
}

// MARK: - TFLBusStopDetailsError Enum
enum TFLBusStopDetailsError: Int
{
    case jsonParse
    case noData
}

// MARK: - TFLBusStopDetails class
class TFLBusStopDetails: TFLNetworkOperationProcessor, TFLNetworkOperationRequestor
{
    fileprivate weak var resultsHandler: TFLBusStopDetailsProcessor?
    fileprivate let stationId: NaptanId
    fileprivate let _request: URLRequest
    var request: URLRequest {
        get {
            return _request
        }
    }
    
    init(stationId: NaptanId, resultsHandler: TFLBusStopDetailsProcessor)
    {
        let method = "StopPoint/\(stationId)"
        _request = URLRequest(url: TFLURL(method: method, parameters: [:]).url as URL)
        self.resultsHandler = resultsHandler
        self.stationId = stationId
    }
    
    func process(data: Data)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "TFLBusStopDetails.processData",
                                code: TFLBusStopDetailsError.jsonParse.rawValue, userInfo: userInfo)
            handle(error: error)
            return
        }
        if let stopPoint = parseDetails(json) {
            if stopPoint.id == stationId { resultsHandler?.process(stopPoint: stopPoint) }
            else {
                for child in stopPoint.children {
                    if child.id == stationId {
                        resultsHandler?.process(stopPoint: child)
                        break
                    }
                }
            }
        }
    }
    
    func handle(error: NSError)
    {
        resultsHandler?.handle(error: error)
    }
}

// MARK: - TFLBusStopDetails Private Functions
private extension TFLBusStopDetails
{
    func parseDetails(_ json: [String: AnyObject]) -> StopPoint?
    {
        do {
            return try StopPoint(json: json)
        }
        catch let error as NSError {
            if error.code == StopPointError.stopLetterKeyNotFound.rawValue {
                return parseChildren(json).first { $0.id == stationId }
            }
            processError(error)
        }
        return nil
    }
    
    func parseChildren(_ json: [String: AnyObject]) -> [StopPoint]
    {
        if let children = json[StopPoint.ChildrenKey] as? [[String: AnyObject]] {
            var parsedChildren = [StopPoint]()
            for child in children {
                do {
                    if let parsedChild = try StopPoint(json: child) {
                        parsedChildren.append(parsedChild)
                    }
                    
                }
                catch let error as NSError {
                    if error.code != StopPointError.stopLetterKeyNotFound.rawValue {
                        processError(error)
                        return []
                    }
                    else {
                        parsedChildren += parseChildren(child)
                    }
                }
            }
            return parsedChildren
        }
        return []
    }
    
    func processError(_ underlyingError: NSError)
    {
        let userInfo = [NSLocalizedDescriptionKey: "JSON response could not be parsed.",
                        NSUnderlyingErrorKey: underlyingError] as [String : Any]
        let error = NSError(domain: "TFLBusArrivalSearch.parseArrivals",
                            code: TFLBusStopDetailsError.jsonParse.rawValue, userInfo: userInfo)
        handle(error: error)
    }
    
    func parseJson(_ data: Data) -> Any?
    {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object", NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "TFLBusArrivalSearch.parseJson",
                                code: TFLBusStopDetailsError.noData.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        return nil
    }
}
