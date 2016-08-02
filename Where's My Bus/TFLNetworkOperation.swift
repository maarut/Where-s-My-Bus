//
//  TFLNetworkOperation.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 27/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation

protocol TFLNetworkOperationRequestor
{
    var request: NSURLRequest { get }
}

protocol TFLNetworkOperationProcessor
{
    func handleError(error: NSError)
    func processData(data: NSData)
}

class TFLNetworkOperation: NSOperation
{
    private let incomingData = NSMutableData()
    private var sessionTask: NSURLSessionTask?
    private lazy var session: NSURLSession = {
        return NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: self, delegateQueue: nil)
    }()
    private let processor: TFLNetworkOperationProcessor
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
    }
}

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
                completionHandler(.Cancel)
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
        defer { finished = true }
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