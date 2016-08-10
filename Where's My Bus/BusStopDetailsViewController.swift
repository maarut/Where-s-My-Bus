//
//  BusStopDetailsViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 05/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

class BusStopDetailsViewController: UITableViewController
{
    var stopPoint: StopPoint?
    private var arrivals = [BusArrival]()
    private var timer: NSTimer?
    private var arrivalRefreshCounter = 30
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refresh(_:)), forControlEvents: .ValueChanged)
        if let stopPoint = stopPoint {
            navigationItem.title = "Stop\(stopPoint.stopLetter.isEmpty ? "" : " \(stopPoint.stopLetter)")"
            TFLClient.instance.busArrivalTimesForStop(stopPoint.id, resultsProcessor: self)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add,
            target: self, action: #selector(refresh(_:)))
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(timerElapsed(_:)),
            userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
        timer?.invalidate()
    }
    
    func timerElapsed(timer: NSTimer)
    {
        if arrivalRefreshCounter == 0 {
            refresh()
            arrivalRefreshCounter = 30
        }
        else {
            arrivalRefreshCounter -= 1
        }
        
    }
    
    func refresh(control: UIRefreshControl)
    {
        refresh()
    }
    
    func refresh()
    {
        if let stopPoint = stopPoint {
            TFLClient.instance.busArrivalTimesForStop(stopPoint.id , resultsProcessor: self)
        }
    }
}

// MARK: - UITableViewDataSource Implementation
extension BusStopDetailsViewController
{
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let lineId = stopPoint?.lines[section].id {
            let lineIdArrivals = arrivals.filter { $0.lineId == lineId }
            return lineIdArrivals.count
        }
        else {
            return 0
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return stopPoint?.lines.count ?? 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return stopPoint?.lines[section].name
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let line = stopPoint?.lines[indexPath.section] {
            let bus = indexPath.row
            let arrival = arrivals.filter { $0.lineId == line.id }[bus]
            let minutes = Int(arrival.ETA / 60.0)
            let cell = tableView.dequeueReusableCellWithIdentifier("busEta") ??
                UITableViewCell(style: .Subtitle, reuseIdentifier: "busEta")
            if minutes == 0 {
                cell.textLabel?.text = "Due"
            }
            else {
                cell.textLabel?.text = "\(minutes) min\(minutes == 1 ? "" : "s")"
            }
            cell.detailTextLabel?.text = arrival.destination
            return cell
        }
        return UITableViewCell()
    }
}

extension BusStopDetailsViewController: TFLBusArrivalSearchResultsProcessor
{
    func handleError(error: NSError)
    {
        NSLog("\(error)")
    }
    
    func processResults(arrivals: [BusArrival])
    {
        Dispatch.mainQueue.async {
            self.arrivals = arrivals
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
}