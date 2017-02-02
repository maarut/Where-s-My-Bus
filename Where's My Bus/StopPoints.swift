//
//  StopPoints.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 28/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import CoreLocation

enum StopPointsError: Int
{
    case keyNotFound
    case stopPointsParsing
}

struct StopPoints
{
    static let CentrePointKey = "centrePoint"
    static let StopPointsKey = "stopPoints"
    
    let centrePoint: CLLocationCoordinate2D
    let stopPoints: [StopPoint]
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: StopPointsError) -> NSError
        {
            return NSError(domain: "StopPoints.init", code: code.rawValue,
                           userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        guard let centrePoint = json[StopPoints.CentrePointKey] as? [Double] else {
            throw makeError("Key \(StopPoints.CentrePointKey) not found.", code: .keyNotFound)
        }
        guard let stopPoints = json[StopPoints.StopPointsKey] as? [[String: AnyObject]] else {
            throw makeError("Key \(StopPoints.StopPointsKey) not found.", code: .keyNotFound)
        }
        self.centrePoint = CLLocationCoordinate2D(latitude: centrePoint[0], longitude: centrePoint[1])
        self.stopPoints = try stopPoints.flatMap {
            do { return try StopPoint(json: $0) }
            catch let error as NSError {
                if error.code == StopPointError.stopLetterKeyNotFound.rawValue {
                    return nil
                }
                let userInfo: [String: AnyObject] =
                    [NSLocalizedDescriptionKey: "Could not parse JSON dictionary for key \(StopPoints.StopPointsKey)." as AnyObject,
                        NSUnderlyingErrorKey: error]
                throw NSError(domain: "StopPoints.init", code: StopPointsError.stopPointsParsing.rawValue,
                    userInfo: userInfo)
            }
        }
        
    }
}
