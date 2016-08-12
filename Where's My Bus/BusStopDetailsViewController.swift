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
    var stopPoint: StopPoint!
    var dataController: DataController!
    
    private var arrivals = [BusArrival]()
    private var timer: NSTimer?
    private var arrivalRefreshCounter = 3000
    private let arrivalRefreshCounterInterval = 3000
    private var favouritedButton: UIBarButtonItem!
    private var addToFavouriteButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(toggleFavourite(_:)), forControlEvents: .ValueChanged)
        if let stopPoint = stopPoint {
            navigationItem.title = "Stop\(stopPoint.stopLetter.isEmpty ? "" : " \(stopPoint.stopLetter)")"
            TFLClient.instance.busArrivalTimesForStop(stopPoint.id, resultsProcessor: self)
        }
        favouritedButton = UIBarButtonItem(image: FavouritesStar.get(.Filled),
            style: .Plain, target: self, action: #selector(toggleFavourite(_:)))
        addToFavouriteButton = UIBarButtonItem(image: FavouritesStar.get(.Empty),
            style: .Plain, target: self, action: #selector(toggleFavourite(_:)))
        navigationItem.rightBarButtonItem = dataController.isFavourite(stopPoint.id) ?
            favouritedButton :
            addToFavouriteButton
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(timerElapsed(_:)),
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
        }
        else {
            arrivalRefreshCounter -= 1
        }
        progressView.progress = Float(arrivalRefreshCounter) / Float(arrivalRefreshCounterInterval)
    }
    
    func toggleFavourite(control: UIRefreshControl)
    {
        if dataController.isFavourite(stopPoint.id) {
            dataController.unfavourite(stopPoint.id)
            navigationItem.rightBarButtonItem = addToFavouriteButton
        }
        else {
            dataController.favourite(stopPoint.id)
            navigationItem.rightBarButtonItem = favouritedButton
        }
        
    }
    
    private func refresh()
    {
        arrivalRefreshCounter = arrivalRefreshCounterInterval
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