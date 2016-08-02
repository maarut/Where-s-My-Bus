//
//  Line.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 29/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation

typealias LineId = String
typealias LineDetails = String

enum LineError: Int
{
    case IdKeyNotFound
    case NameKeyNotFound
    case URIKeyNotFound
}

struct Line
{
    static let IdKey = "id"
    static let NameKey = "name"
    static let UriKey = "uri"
    
    let id: LineId
    let name: String
    let uri: LineDetails
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(errorString: String, code: LineError) -> NSError
        {
            return NSError(domain: "Line.init", code: code.rawValue,
                           userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        guard let id = json[Line.IdKey] as? String else {
            throw makeError("Key \(Line.IdKey) not found.", code: .IdKeyNotFound)
        }
        guard let name = json[Line.NameKey] as? String else {
            throw makeError("Key \(Line.NameKey) not found.", code: .NameKeyNotFound)
        }
        guard let uri = json[Line.UriKey] as? String else {
            throw makeError("Key \(Line.UriKey) not found.", code: .URIKeyNotFound)
        }
        self.id = LineId(id)
        self.name = name
        self.uri = LineDetails(uri)
    }
}