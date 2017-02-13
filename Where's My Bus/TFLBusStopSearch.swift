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
    func process(stopPoints: StopPoints)
    func handle(error: NSError)
}

// MARK: - TFLBusStopSearchErrorCodes Enum
enum TFLBusStopSearchError: Int
{
    case noData
    case jsonParse
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
    fileprivate weak var resultsHandler: TFLBusStopSearchResultsProcessor?
    fileprivate let _request: URLRequest
    var request: URLRequest {
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
        _request = URLRequest(url: TFLURL(method: "StopPoint", parameters: parameters).url as URL)
        self.resultsHandler = resultsHandler
    }
    
    func process(data: Data)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "TFLBusStopSearch.processData",
                code: TFLBusStopSearchError.jsonParse.rawValue, userInfo: userInfo)
            handle(error: error)
            return
        }
        if let stopPoints = parseStopPoints(json) {
            resultsHandler?.process(stopPoints: stopPoints)
        }
    }
    
    func handle(error: NSError) {
        resultsHandler?.handle(error: error)
    }
}

// MARK: - TFLBusStopSearch Private Methods
private extension TFLBusStopSearch
{
    func parseStopPoints(_ data: [String: AnyObject]) -> StopPoints?
    {
        do {
            return try StopPoints(json: data)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "JSON response could not be parsed.",
                NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "TFLBusStopSearch.processData",
                code: TFLBusStopSearchError.jsonParse.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        return nil
    }
    
    func parseJson(_ data: Data) -> Any?
    {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object", NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "TFLBusStopSearch.parseJson",
                code: TFLBusStopSearchError.noData.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        return nil
    }
}
