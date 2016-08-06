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
    case StopLetterKeyNotFound
    case KeyNotFound
    case LineParsing
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
    
    let location: CLLocationCoordinate2D
    let id: NaptanId
    let stopLetter: String
    let lines: [Line]
    let name: String
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(errorString: String, code: StopPointError) -> NSError
        {
            return NSError(domain: "StopPoint.init", code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        guard let lat = json[StopPoint.LatKey] as? Double else {
            throw makeError("Key \(StopPoint.LatKey) not found.", code: .KeyNotFound)
        }
        guard let lon = json[StopPoint.LonKey] as? Double else {
            throw makeError("Key \(StopPoint.LonKey) not found.", code: .KeyNotFound)
        }
        guard let name = json[StopPoint.NameKey] as? String else {
            throw makeError("Key \(StopPoint.NameKey) not found.", code: .KeyNotFound)
        }
        guard let stopLetter = json[StopPoint.StopLetterKey] as? String else {
            throw makeError("Key \(StopPoint.StopLetterKey) not found.", code: .StopLetterKeyNotFound)
        }
        guard let linesJson = json[StopPoint.LinesKey] as? [[String: AnyObject]] else {
            throw makeError("Key \(StopPoint.LinesKey) not found.", code: .KeyNotFound)
        }
        guard let id = json[StopPoint.IdKey] as? String else {
            throw makeError("Key \(StopPoint.IdKey) not found.", code: .KeyNotFound)
        }
        self.location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.stopLetter = stopLetter
        self.name = name
        self.id = NaptanId(id)
        do {
            self.lines = try linesJson.flatMap { try Line(json: $0) }
        }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey: "Could not parse JSON dictionary for key \(StopPoint.LinesKey).",
                NSUnderlyingErrorKey: error]
            throw NSError(domain: "StopPoint.init", code: StopPointError.LineParsing.rawValue, userInfo: userInfo)
        }
    }
}