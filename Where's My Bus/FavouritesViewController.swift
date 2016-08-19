//
//  FavouritesViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 25/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit
import CoreData

class FavouritesViewController: UITableViewController
{
    var dataController: DataController!
    
    private var allFavourites: NSFetchedResultsController!
    private var favouritesMap = [NaptanId: FavouritesDetails]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refresh(_:)), forControlEvents: .ValueChanged)
        allFavourites = dataController.allFavourites()
        allFavourites.delegate = self
        do {
            try allFavourites.performFetch()
        }
        catch let error as NSError {
            NSLog("\(error)\n\(error.localizedDescription)")
        }
        mapFavourites()
    }
    
    func refresh(control: UIRefreshControl)
    {
        control.endRefreshing()
        for detail in favouritesMap.values {
            detail.refresh()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier {
        case .Some("AddStopSegue"):
            (segue.destinationViewController as! SearchStopViewController).dataController = dataController
            break
        case .Some("BusStopDetailSegue"):
            let nextVC = (segue.destinationViewController as! BusStopDetailsContainerViewController)
            nextVC.dataController = dataController
            nextVC.stationId = (sender as? Favourite)?.naptanId
            break
        default:
            break
        }
    }
    
    private func mapFavourites()
    {
        let fetchedObjects = allFavourites.fetchedObjects ?? []
        for favourite in fetchedObjects {
            if let stationId = (favourite as! Favourite).naptanId {
                if favouritesMap[stationId] == nil {
                    favouritesMap[stationId] = FavouritesDetails(stationId: stationId, viewController: self)
                }
                favouritesMap[stationId]!.refresh()
            }
        }
        for stationId in favouritesMap.keys {
            if !fetchedObjects.contains( { ($0 as! Favourite).naptanId == stationId }) {
                favouritesMap[stationId] = nil
            }
        }
    }
}

// MARK: - UITableViewDataSource Implementation
extension FavouritesViewController
{
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return allFavourites.fetchedObjects?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCellWithIdentifier("Favourite") as? FavouritesCell,
            let stationId = (allFavourites.fetchedObjects?[indexPath.row] as? Favourite)?.naptanId,
            let details = favouritesMap[stationId] {
            cell.stopName.text =
                "\(details.stopPointLetter.isEmpty ? "" : "\(details.stopPointLetter) - ")\(details.stopPointName)"
            for i in 0 ..< details.arrivals.count {
                let routeInfo: ETAInformationView
                if i < cell.stackView.arrangedSubviews.count {
                    routeInfo = cell.stackView.arrangedSubviews[i] as! ETAInformationView
                }
                else {
                    routeInfo = ETAInformationView(frame: CGRectZero)
                    cell.stackView.addArrangedSubview(routeInfo)
                }
                routeInfo.route.text = "\(details.arrivals[i].lineName)"
                routeInfo.routeBorder.layer.cornerRadius = 3.0
                routeInfo.eta.text = "\(details.arrivals[i].ETA)"
                UIView.animateWithDuration(0.3) { routeInfo.hidden = false }
            }
            if details.arrivals.count < cell.stackView.arrangedSubviews.count {
                for i in details.arrivals.count ..< cell.stackView.arrangedSubviews.count {
                    cell.stackView.arrangedSubviews[i].hidden = true
                }
                cell.stackView.layoutIfNeeded()
            }
            cell.layoutIfNeeded()
            return cell
        }
        return UITableViewCell()
    }
    
}

// MARK: - UITableViewDelegate Implementation
extension FavouritesViewController
{
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let favourite = allFavourites.fetchedObjects?[indexPath.row] as? Favourite {
            performSegueWithIdentifier("BusStopDetailSegue", sender: favourite)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate Implementation
extension FavouritesViewController: NSFetchedResultsControllerDelegate
{
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        Dispatch.mainQueue.async {
            self.mapFavourites()
            self.tableView.reloadData()
        }
    }
}

private class FavouritesDetails
{
    let stationId: NaptanId
    var stopPointLetter: String
    var stopPointName: String
    var lines: [LineId]
    var arrivals: [BusArrival]
    weak var viewController: FavouritesViewController?
    
    init(stationId: NaptanId, viewController: FavouritesViewController)
    {
        self.stationId = stationId
        arrivals = []
        stopPointName = ""
        stopPointLetter = ""
        lines = []
        self.viewController = viewController
        TFLClient.instance.detailsForBusStop(stationId, resultsProcessor: self)
    }
    
    func refresh()
    {
        TFLClient.instance.busArrivalTimesForStop(stationId, resultsProcessor: self)
    }
    
    private func reloadTableView()
    {
        if let index = viewController?.allFavourites.fetchedObjects?
            .indexOf( { ($0 as! Favourite).naptanId == stationId } ) {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            viewController?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
}

extension FavouritesDetails: TFLBusStopDetailsProcessor
{
    func handleError(error: NSError)
    {
        NSLog("\(error)\n\(error.localizedDescription)")
    }
    
    func processStopPoint(stopPoint: StopPoint)
    {
        Dispatch.mainQueue.async {
            self.stopPointLetter = stopPoint.stopLetter
            self.stopPointName = stopPoint.name
            self.lines = stopPoint.lines.map { $0.id }
            self.reloadTableView()
        }
    }
}

extension FavouritesDetails: TFLBusArrivalSearchResultsProcessor
{
    func processResults(arrivals: [BusArrival])
    {
        Dispatch.mainQueue.async {
            self.arrivals = []
            for line in self.lines {
                if let arrival = arrivals.filter( { $0.lineId == line } ).sort( { $0.ETA < $1.ETA } ).first {
                    self.arrivals.append(arrival)
                }
            }
            self.reloadTableView()
        }
    }
}