//
//  TFLNetworkOperation.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 27/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation
import UIKit

// MARK: - TFLNetworkOperationRequestor Protocol
protocol TFLNetworkOperationRequestor
{
    var request: NSURLRequest { get }
}

// MARK: - TFLNetworkOperationProcessor Protocol
protocol TFLNetworkOperationProcessor
{
    func handleError(error: NSError)
    func processData(data: NSData)
}

// MARK: - TFLNetworkOperationError Enum
enum TFLNetworkOperationError: Int
{
    case InvalidStatus = 900
    case Response
    case JsonParse
}

// MARK: - TFLNetworkOperation
class TFLNetworkOperation: NSOperation
{
    private let incomingData = NSMutableData()
    private var sessionTask: NSURLSessionTask?
    private lazy var session: NSURLSession = {
        return NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: self, delegateQueue: nil)
    }()
    private var processor: TFLNetworkOperationProcessor
    private let requestor: TFLNetworkOperationRequestor
    
    var _finished: Bool = false
    override var finished: Bool {
        get {
            return _finished
        }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    init(processor: TFLNetworkOperationProcessor, requestor: TFLNetworkOperationRequestor)
    {
        self.processor = processor
        self.requestor = requestor
        super.init()
    }
    
    override func start()
    {
        if cancelled {
            finished = true
            return
        }
        sessionTask = session.dataTaskWithRequest(requestor.request)
        sessionTask!.resume()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
}

// MARK: - NSURLSessionDataDelegate Implementation
extension TFLNetworkOperation: NSURLSessionDataDelegate
{
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse,
        completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
        if cancelled {
            sessionTask?.cancel()
            finished = true
            completionHandler(.Cancel)
            return
        }
        if let response = response as? NSHTTPURLResponse {
            if !(response.statusCode ~= 200 ..< 300) {

                let invalidStatusProcessor = InvalidStatusProcessor(processor: processor)
                processor = invalidStatusProcessor
            }
        }
        completionHandler(.Allow)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)
    {
        if cancelled {
            sessionTask?.cancel()
            finished = true
            return
        }
        incomingData.appendData(data)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        defer {
            finished = true
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        if cancelled {
            sessionTask?.cancel()
            return
        }
        guard error == nil else {
            processor.handleError(error!)
            return
        }
        processor.processData(NSData(data: incomingData))
    }
}

// MARK: - InvalidStatusProcessor
private class InvalidStatusProcessor: TFLNetworkOperationProcessor
{
    let processor: TFLNetworkOperationProcessor
    init(processor: TFLNetworkOperationProcessor)
    {
        self.processor = processor
        NSLog("Invalid status detected")
    }
    
    func handleError(error: NSError)
    {
        processor.handleError(error)
    }
    
    func processData(data: NSData)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: TFLNetworkOperationError.JsonParse.rawValue, userInfo: userInfo)
            handleError(error)
            return
        }
        if let message = json["message"] as? String {
            let userInfo = [NSLocalizedDescriptionKey: message]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: TFLNetworkOperationError.InvalidStatus.rawValue, userInfo: userInfo)
            handleError(error)
        }
        else {
            let userInfo = [NSLocalizedDescriptionKey: "Invalid status received."]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: TFLNetworkOperationError.InvalidStatus.rawValue, userInfo: userInfo)
            handleError(error)
        }
        
    }
    
    func parseJson(data: NSData) -> AnyObject?
    {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object", NSUnderlyingErrorKey: error]
            let error = NSError(domain: "InvalidStatusProcessor.parseJson",
                code: TFLNetworkOperationError.Response.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return nil
    }
}