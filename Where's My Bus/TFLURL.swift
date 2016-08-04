//
//  TFLURL.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 27/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation

class TFLURL
{
    let url: NSURL
    
    init(method: String, parameters: [String: Any])
    {
        let url = NSURLComponents()
        url.scheme = TFLConstants.API.Scheme
        url.host = TFLConstants.API.Host
        url.path = "/\(method)"
        
        url.queryItems = parameters.map { NSURLQueryItem(name: $0, value: "\($1)") }
        url.queryItems!.append(NSURLQueryItem(name: TFLConstants.ParameterKeys.AppId, value: TFLConstants.API.AppId))
        url.queryItems!.append(NSURLQueryItem(name: TFLConstants.ParameterKeys.AppKey, value: TFLConstants.API.AppKey))
        
        self.url = url.URL!
    }
}
