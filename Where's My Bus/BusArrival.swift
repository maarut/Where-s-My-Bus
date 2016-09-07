//
//  BusArrivals.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 05/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation

typealias BusArrivalId = Int

func ==(lhs: BusArrival, rhs: BusArrival) -> Bool
{
    return lhs.id == rhs.id
}

enum BusArrivalsError: Int
{
    case KeyNotFound
}

struct BusArrival: Equatable
{
    static let IdKey = "id"
    static let NumberPlateKey = "vehicleId"
    static let LineIdKey = "lineId"
    static let LineNameKey = "lineName"
    static let DestinationNameKey = "destinationName"
    static let ETAKey = "timeToStation"
    static let TowardsKey = "towards"
    static let BearingKey = "bearing"
    
    let id: BusArrivalId
    let numberPlate: String
    let ETA: NSTimeInterval
    let destination: String
    let towards: String
    let lineId: LineId
    let lineName: String
    let bearing: Double
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(errorString: String, code: LineError) -> NSError
        {
            return NSError(domain: "BusArrivals.init", code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        guard let id = Int(json[BusArrival.IdKey] as? String ?? "") else {
            throw makeError("Key \(BusArrival.IdKey) not found.", code: .KeyNotFound)
        }
        guard let numberPlate = json[BusArrival.NumberPlateKey] as? String else {
            throw makeError("Key \(BusArrival.NumberPlateKey) not found.", code: .KeyNotFound)
        }
        guard let lineId = json[BusArrival.LineIdKey] as? String else {
            throw makeError("Key \(BusArrival.LineIdKey) not found.", code: .KeyNotFound)
        }
        guard let lineName = json[BusArrival.LineNameKey] as? String else {
            throw makeError("Key \(BusArrival.LineNameKey) not found.", code: .KeyNotFound)
        }
        guard let destination = json[BusArrival.DestinationNameKey] as? String else {
            throw makeError("Key \(BusArrival.DestinationNameKey) not found.", code: .KeyNotFound)
        }
        guard let eta = json[BusArrival.ETAKey] as? Int else {
            throw makeError("Key \(BusArrival.ETAKey) not found.", code: .KeyNotFound)
        }
        guard let towards = json[BusArrival.TowardsKey] as? String else {
            throw makeError("Key \(BusArrival.TowardsKey) not found.", code: .KeyNotFound)
        }
        guard let bearing = Double((json[BusArrival.BearingKey] as? String) ?? "") else {
            throw makeError("Key \(BusArrival.BearingKey) not found.", code: .KeyNotFound)
        }
        self.id = BusArrivalId(id)
        self.numberPlate = numberPlate
        self.ETA = NSTimeInterval(eta)
        self.destination = destination
        self.towards = towards
        self.lineId = LineId(lineId)
        self.lineName = lineName
        self.bearing = bearing
    }
}