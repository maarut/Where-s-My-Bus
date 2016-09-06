//
//  BusStopDetailsViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 05/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

enum BusStopDetailsSortOrder: Int
{
    case Route
    case ETA
}

class BusStopDetailsViewController: UITableViewController
{
    var stopPoint: StopPoint?
    var dataController: DataController!
    var sortOrder: BusStopDetailsSortOrder! {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var arrivals = [BusArrival]()
    private var timer: NSTimer?
    private var arrivalRefreshCounter = 3000
    private let arrivalRefreshCounterInterval = 3000
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
        if let stopPoint = stopPoint {
            TFLClient.instance.busArrivalTimesForStop(stopPoint.id, resultsProcessor: self)
        }
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(timerElapsed(_:)),
                userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    func timerElapsed(timer: NSTimer)
    {
        if arrivalRefreshCounter == 0 {
            refresh()
        }
        else {
            arrivalRefreshCounter -= 1
        }
        progressView.progress = Float(arrivalRefreshCounter) / Float(arrivalRefreshCounterInterval)
    }
    
    func refresh()
    {
        if progressView.hidden {
            progressView.hidden = false
            timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(timerElapsed(_:)),
                userInfo: nil, repeats: true)
        }
        arrivalRefreshCounter = arrivalRefreshCounterInterval
        progressView.progress = 1.0
        if let stopPoint = stopPoint {
            TFLClient.instance.busArrivalTimesForStop(stopPoint.id , resultsProcessor: self)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
    }
}

// MARK: - UITableViewDataSource Implementation
extension BusStopDetailsViewController
{
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch sortOrder! {
        case .Route:
            if let lineId = stopPoint?.lines[section].id {
                let lineIdArrivals = arrivals.filter { $0.lineId == lineId }
                return lineIdArrivals.count
            }
            break
        case .ETA:
            return arrivals.count
        }
        return 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        switch sortOrder! {
        case .ETA:
            return 1
        case .Route:
            return stopPoint?.lines.count ?? 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return sortOrder == .ETA ? nil : stopPoint?.lines[section].name
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCellWithIdentifier(identifier()) as? BusArrivalDetailsCell,
            let arrival = arrival(indexPath) {
            let minutes = Int(arrival.ETA / 60.0)
            if minutes == 0 { cell.eta.text = "Due" }
            else { cell.eta.text = "\(minutes) min\(minutes == 1 ? "" : "s")" }
            cell.direction.text = arrival.destination
            cell.numberPlate.text = arrival.numberPlate
            cell.numberPlateBorder.layer.cornerRadius = 3.0
            cell.numberPlateBorder.layer.borderWidth = 1.0
            configure(cell, with: arrival.lineName)
            return cell
        }
        return UITableViewCell()
    }
    
    private func identifier() -> String
    {
        let identifier: String
        switch sortOrder! {
        case .ETA: identifier = "eta"
        case .Route: identifier = "route"
        }
        return identifier
    }
    
    private func configure(cell: BusArrivalDetailsCell, with arrival: String)
    {
        switch sortOrder! {
        case .ETA:
            cell.route.text = arrival
            cell.routeBorder.layer.cornerRadius = 3.0
            break
        case .Route:
            break
        }
    }
    
    private func arrival(indexPath: NSIndexPath) -> BusArrival?
    {
        if sortOrder == .Route {
            if let line = stopPoint?.lines[indexPath.section] {
                return arrivals.filter { $0.lineId == line.id }[indexPath.row]
            }
        }
        else if sortOrder == .ETA {
            return arrivals.sort { $0.ETA < $1.ETA }[indexPath.row]
        }
        return nil
    }
}

// MARK: - TFLBusArrivalSearchResultsProcessor Implementation
extension BusStopDetailsViewController: TFLBusArrivalSearchResultsProcessor
{
    func handleError(error: NSError)
    {
        NSLog("\(error)")
        Dispatch.mainQueue.async {
            if self.presentedViewController == nil {
                let alertVC = UIAlertController(title: "Error Occurred", message: error.localizedDescription,
                    preferredStyle: .Alert)
                alertVC.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                self.presentViewController(alertVC, animated: true, completion: nil)
                self.timer?.invalidate()
                self.timer = nil
                self.progressView.hidden = true
            }
        }
    }
    
    func processResults(arrivals: [BusArrival])
    {
        Dispatch.mainQueue.async {
            self.arrivals = arrivals
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
}