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
    var stationId: NaptanId?
    var dataController: DataController!
    var sortOrder: BusStopDetailsSortOrder! {
        didSet {
            NSLog("\(sortOrder)")
            tableView.reloadData()
        }
    }
    
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
        refreshControl!.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
        favouritedButton = UIBarButtonItem(image: FavouritesStar.get(.Filled),
            style: .Plain, target: self, action: #selector(toggleFavourite(_:)))
        addToFavouriteButton = UIBarButtonItem(image: FavouritesStar.get(.Empty),
            style: .Plain, target: self, action: #selector(toggleFavourite(_:)))
        if let stopPoint = stopPoint {
            stationId = stopPoint.id
            TFLClient.instance.busArrivalTimesForStop(stopPoint.id, resultsProcessor: self)
            navigationItem.rightBarButtonItem = dataController.isFavourite(stopPoint.id) ?
                favouritedButton :
                addToFavouriteButton
            updateNavigationItemTitle()
        }
        else if let stationId = stationId {
            TFLClient.instance.detailsForBusStop(stationId, resultsProcessor: self)
            navigationItem.rightBarButtonItem = dataController.isFavourite(stationId) ?
                favouritedButton :
                addToFavouriteButton
        }
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
        if let stopPoint = stopPoint {
            if dataController.isFavourite(stopPoint.id) {
                dataController.unfavourite(stopPoint.id)
                navigationItem.rightBarButtonItem = addToFavouriteButton
            }
            else {
                dataController.favourite(stopPoint.id)
                navigationItem.rightBarButtonItem = favouritedButton
            }
        }
    }
    
    private func updateNavigationItemTitle()
    {
        if let stopPoint = stopPoint {
            navigationItem.title = stopPoint.stopLetter.isEmpty ? stopPoint.name : "Stop \(stopPoint.stopLetter)"
        }
    }
    
    func refresh()
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
        if let sortOrder = sortOrder {
            switch sortOrder {
            case .Route:
                if let lineId = stopPoint?.lines[section].id {
                    let lineIdArrivals = arrivals.filter { $0.lineId == lineId }
                    return lineIdArrivals.count
                }
                break
            case .ETA:
                return arrivals.count
            }
        }
        return 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if let sortOrder = sortOrder {
            switch sortOrder {
            case .ETA:
                return 1
            case .Route:
                return stopPoint?.lines.count ?? 0
            }
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return sortOrder == .ETA ? nil : stopPoint?.lines[section].name
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCellWithIdentifier("busEta"),
            let arrival = arrival(indexPath) {
            let minutes = Int(arrival.ETA / 60.0)
            if minutes == 0 { (cell.viewWithTag(1) as? UILabel)?.text = "Due" }
            else { (cell.viewWithTag(1) as? UILabel)?.text = "\(minutes) min\(minutes == 1 ? "" : "s")" }
            (cell.viewWithTag(2) as? UILabel)?.text = arrival.destination
            (cell.viewWithTag(3) as? UILabel)?.text = arrival.numberPlate
            if let borderView = cell.viewWithTag(4) {
                borderView.layer.cornerRadius = 3.0
                borderView.layer.borderWidth = 1.0
            }
            
            return cell
        }
        return UITableViewCell()
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

// MARK: - TFLBusStopDetailsProcessor Implementation
// handleError(_:) implemented in TFLBusArrivalSearchResultsProcessor extension
extension BusStopDetailsViewController: TFLBusStopDetailsProcessor
{
    func processStopPoint(stopPoint: StopPoint)
    {
        self.stopPoint = stopPoint
        updateNavigationItemTitle()
        TFLClient.instance.busArrivalTimesForStop(stopPoint.id, resultsProcessor: self)
    }
}