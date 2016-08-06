//
//  TFLBusStopSearch.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 29/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - TFLBusStopSearchResultsProcessor Protocol
protocol TFLBusStopSearchResultsProcessor: class
{
    func processStopPoints(stopPoints: StopPoints)
    func handleError(error: NSError)
}

// MARK: - TFLBusStopSearchErrorCodes Enum
enum TFLBusStopSearchErrorCodes: Int
{
    case NoData
    case JsonParse
}

// MARK: - TFLBusStopSearchCriteria Struct
struct TFLBusStopSearchCriteria
{
    static let MaxRadius: Int32 = 1000
    let centrePoint: CLLocationCoordinate2D
    let radius: Int32
    
    init(centrePoint: CLLocationCoordinate2D, radius: Int32)
    {
        self.centrePoint = centrePoint
        self.radius = radius < TFLBusStopSearchCriteria.MaxRadius ? radius : TFLBusStopSearchCriteria.MaxRadius
    }
}

// MARK: - TFLBusStopSearch Class
class TFLBusStopSearch: TFLNetworkOperationRequestor, TFLNetworkOperationProcessor
{
    private weak var resultsHandler: TFLBusStopSearchResultsProcessor?
    private let _request: NSURLRequest
    var request: NSURLRequest {
        get {
            return _request
        }
    }

    init(searchCriteria: TFLBusStopSearchCriteria, resultsHandler: TFLBusStopSearchResultsProcessor)
    {
        let parameters: [String: Any] = [
            "stopTypes": "NaptanPublicBusCoachTram",
            "lat": searchCriteria.centrePoint.latitude,
            "lon": searchCriteria.centrePoint.longitude,
            "radius": searchCriteria.radius
        ]
        _request = NSURLRequest(URL: TFLURL(method: "StopPoint", parameters: parameters).url)
        self.resultsHandler = resultsHandler
    }
    
    func processData(data: NSData)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "TFLBusStopSearch.processData",
                code: TFLBusStopSearchErrorCodes.JsonParse.rawValue, userInfo: userInfo)
            handleError(error)
            return
        }
        if let stopPoints = parseStopPoints(json) {
            resultsHandler?.processStopPoints(stopPoints)
        }
    }
    
    func handleError(error: NSError) {
        resultsHandler?.handleError(error)
    }
}

// MARK: - TFLBusStopSearch Private Methods
private extension TFLBusStopSearch
{
    func parseStopPoints(data: [String: AnyObject]) -> StopPoints?
    {
        let stopPoints: StopPoints?
        do {
            stopPoints = try StopPoints(json: data)
        }
        catch let error as NSError {
            stopPoints = nil
            
            let userInfo = [NSLocalizedDescriptionKey: "JSON response could not be parsed.",
                NSUnderlyingErrorKey: error]
            let error = NSError(domain: "TFLBusStopSearch.processData",
                code: TFLBusStopSearchErrorCodes.JsonParse.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return stopPoints
    }
    
    func parseJson(data: NSData) -> AnyObject?
    {
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        }
        catch let error as NSError {
            parsedResult = nil
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object", NSUnderlyingErrorKey: error]
            let error = NSError(domain: "TFLBusStopSearch.parseJson",
                code: TFLBusStopSearchErrorCodes.NoData.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return parsedResult
    }
}
