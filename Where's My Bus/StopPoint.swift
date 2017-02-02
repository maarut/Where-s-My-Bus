//
//  StopPoint.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 28/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import CoreLocation


typealias NaptanId = String

enum StopPointError: Int
{
    case stopLetterKeyNotFound
    case keyNotFound
    case lineParsing
}

func ==(lhs: StopPoint, rhs: StopPoint) -> Bool
{
    return lhs.id == rhs.id
}

struct StopPoint: Equatable
{
    static let LatKey = "lat"
    static let LonKey = "lon"
    static let StopLetterKey = "stopLetter"
    static let IdKey = "id"
    static let LinesKey = "lines"
    static let NameKey = "commonName"
    static let ChildrenKey = "children"
    static let StopTypeKey = "stopType"
    
    let location: CLLocationCoordinate2D
    let id: NaptanId
    let stopLetter: String
    let lines: [Line]
    let name: String
    let children: [StopPoint]
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: StopPointError) -> NSError
        {
            return NSError(domain: "StopPoint.init", code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        guard let lat = json[StopPoint.LatKey] as? Double else {
            throw makeError("Key \(StopPoint.LatKey) not found.", code: .keyNotFound)
        }
        guard let lon = json[StopPoint.LonKey] as? Double else {
            throw makeError("Key \(StopPoint.LonKey) not found.", code: .keyNotFound)
        }
        guard let name = json[StopPoint.NameKey] as? String else {
            throw makeError("Key \(StopPoint.NameKey) not found.", code: .keyNotFound)
        }
        guard let stopLetter = json[StopPoint.StopLetterKey] as? String else {
            throw makeError("Key \(StopPoint.StopLetterKey) not found.", code: .stopLetterKeyNotFound)
        }
        guard let linesJson = json[StopPoint.LinesKey] as? [[String: AnyObject]] else {
            throw makeError("Key \(StopPoint.LinesKey) not found.", code: .keyNotFound)
        }
        guard let id = json[StopPoint.IdKey] as? String else {
            throw makeError("Key \(StopPoint.IdKey) not found.", code: .keyNotFound)
        }
        guard let children = json[StopPoint.ChildrenKey] as? [[String: AnyObject]] else {
            throw makeError("Key \(StopPoint.ChildrenKey) not found.", code: .keyNotFound)
        }
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.stopLetter = stopLetter.hasPrefix("-") ? "" : stopLetter
        self.name = name
        self.id = NaptanId(id)
        do {
            self.lines = try linesJson.flatMap { try Line(json: $0) }.sorted { $0.id < $1.id }
        }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey: "Could not parse JSON dictionary for key \(StopPoint.LinesKey)." as AnyObject,
                NSUnderlyingErrorKey: error]
            throw NSError(domain: "StopPoint.init", code: StopPointError.lineParsing.rawValue, userInfo: userInfo)
        }
        self.children = try children.flatMap {
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
