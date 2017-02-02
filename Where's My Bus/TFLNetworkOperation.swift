//
//  TFLNetworkOperation.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 27/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import Foundation

// MARK: - TFLNetworkOperationRequestor Protocol
protocol TFLNetworkOperationRequestor
{
    var request: URLRequest { get }
}

// MARK: - TFLNetworkOperationProcessor Protocol
protocol TFLNetworkOperationProcessor
{
    func handleError(_ error: NSError)
    func processData(_ data: Data)
}

// MARK: - TFLNetworkOperationError Enum
enum TFLNetworkOperationError: Int
{
    case invalidStatus = 900
    case response
    case jsonParse
}

// MARK: - TFLNetworkOperation
class TFLNetworkOperation: Operation
{
    fileprivate let incomingData = NSMutableData()
    fileprivate var sessionTask: URLSessionTask?
    fileprivate lazy var session: Foundation.URLSession = {
        return Foundation.URLSession(configuration: URLSessionConfiguration.default,
            delegate: self, delegateQueue: nil)
    }()
    fileprivate var processor: TFLNetworkOperationProcessor
    fileprivate let requestor: TFLNetworkOperationRequestor
    
    var _finished: Bool = false
    override var isFinished: Bool {
        get {
            return _finished
        }
        set {
            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
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
        if isCancelled {
            isFinished = true
            return
        }
        sessionTask = session.dataTask(with: requestor.request)
        sessionTask!.resume()
    }
}

// MARK: - NSURLSessionDataDelegate Implementation
extension TFLNetworkOperation: URLSessionDataDelegate
{
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        if isCancelled {
            sessionTask?.cancel()
            isFinished = true
            completionHandler(.cancel)
            return
        }
        if let response = response as? HTTPURLResponse {
            if !(response.statusCode ~= 200 ..< 300) {

                let invalidStatusProcessor = InvalidStatusProcessor(processor: processor)
                processor = invalidStatusProcessor
            }
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        if isCancelled {
            sessionTask?.cancel()
            isFinished = true
            return
        }
        incomingData.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        defer { isFinished = true }
        if isCancelled {
            sessionTask?.cancel()
            return
        }
        guard error == nil else {
            processor.handleError(error! as NSError)
            return
        }
        processor.processData(NSData(data: incomingData as Data) as Data)
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
    
    func handleError(_ error: NSError)
    {
        processor.handleError(error)
    }
    
    func processData(_ data: Data)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: TFLNetworkOperationError.jsonParse.rawValue, userInfo: userInfo)
            handleError(error)
            return
        }
        if let message = json["message"] as? String {
            let userInfo = [NSLocalizedDescriptionKey: message]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: TFLNetworkOperationError.invalidStatus.rawValue, userInfo: userInfo)
            handleError(error)
        }
        else {
            let userInfo = [NSLocalizedDescriptionKey: "Invalid status received."]
            let error = NSError(domain: "InvalidStatusProcessor.processData",
                code: TFLNetworkOperationError.invalidStatus.rawValue, userInfo: userInfo)
            handleError(error)
        }
        
    }
    
    func parseJson(_ data: Data) -> Any?
    {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object", NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "InvalidStatusProcessor.parseJson",
                code: TFLNetworkOperationError.response.rawValue, userInfo: userInfo)
            handleError(error)
        }
        return nil
    }
}
