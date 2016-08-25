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
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet var longPressGesture: UILongPressGestureRecognizer!
    @IBOutlet var addStopButton: UIBarButtonItem!
    private var doneButton: UIBarButtonItem!
    
    var dataController: DataController!
    
    private var allFavourites: NSFetchedResultsController!
    private var favouritesMap = [NaptanId: FavouritesDetails]()
    private var timer: NSTimer?
    private var arrivalRefreshCounter = 3000
    private let arrivalRefreshCounterInterval = 3000
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        navigationItem.title = "Favourite Bus Stops"
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 800
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
        doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(doneTapped(_:)))
        allFavourites = dataController.allFavourites()
        allFavourites.delegate = self
        do { try allFavourites.performFetch() }
        catch let error as NSError { NSLog("\(error)\n\(error.localizedDescription)") }
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
            nextVC.stopPoint = favouritesMap[(sender as? NaptanId)!]?.stopPoint
            break
        default:
            break
        }
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedRow, animated: true)
        }
        refreshProgressViewVisibility()
        mapFavourites()
        tableView.reloadData()
    }
    
    private func refreshProgressViewVisibility()
    {
        if allFavourites.fetchedObjects?.count ?? 0 == 0 {
            timer?.invalidate()
            timer = nil
            UIView.animateWithDuration(0.3) { self.progressView.hidden = true }
        }
        else {
            if !(timer?.valid ?? false) {
                arrivalRefreshCounter = arrivalRefreshCounterInterval
                timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self,
                    selector: #selector(self.timerElapsed(_:)), userInfo: nil, repeats: true)
                UIView.animateWithDuration(0.3) { self.progressView.hidden = false }
            }
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
    
    private func configureCell(cell: FavouritesCell, with details: FavouritesDetails)
    {
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
            let minutesToArrival = Int(details.arrivals[i].ETA / 60.0)
            routeInfo.route.text = "\(details.arrivals[i].lineName)"
            routeInfo.routeBorder.layer.cornerRadius = 3.0
            routeInfo.towards.text = details.arrivals[i].destination
            if minutesToArrival == 0 { routeInfo.eta.text = "Due" }
            else { routeInfo.eta.text = "\(minutesToArrival) min\(minutesToArrival == 1 ? "" : "s")" }
            routeInfo.hidden = false
        }
        if details.arrivals.count < cell.stackView.arrangedSubviews.count {
            for i in details.arrivals.count ..< cell.stackView.arrangedSubviews.count {
                cell.stackView.arrangedSubviews[i].hidden = true
            }
            cell.stackView.layoutIfNeeded()
        }
        cell.showsReorderControl = true
        cell.layoutIfNeeded()
    }
}

// MARK: - Event Handlers
extension FavouritesViewController
{
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
        arrivalRefreshCounter = arrivalRefreshCounterInterval
        progressView.progress = 1.0
        for detail in favouritesMap.values {
            detail.refresh()
        }
        refreshControl?.endRefreshing()
    }
    
    func doneTapped(button: UIBarButtonItem)
    {
        tableView.setEditing(false, animated: true)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self,
            selector: #selector(self.timerElapsed(_:)), userInfo: nil, repeats: true)
        navigationItem.setRightBarButtonItem(addStopButton, animated: true)
    }
    
    @IBAction func longPressRecognised(sender: UILongPressGestureRecognizer)
    {
        switch sender.state {
        case .Ended:
            tableView.setEditing(true, animated: true)
            timer?.invalidate()
            timer = nil
            navigationItem.setRightBarButtonItem(doneButton, animated: true)
            break
        default:
            break
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
        guard let cell = tableView.dequeueReusableCellWithIdentifier("Favourite") as? FavouritesCell else {
            fatalError("Could not dequeue cell with identifier \"Favourite\". This should not happen.")
        }
        if let stationId = (allFavourites.fetchedObjects?[indexPath.row] as? Favourite)?.naptanId,
            let details = favouritesMap[stationId] {
            configureCell(cell, with: details)
            return cell
        }
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath,
        toIndexPath destinationIndexPath: NSIndexPath)
    {
        var favourites = self.allFavourites.fetchedObjects
        if let obj = favourites?.removeAtIndex(sourceIndexPath.row) {
            favourites?.insert(obj, atIndex: destinationIndexPath.row)
        }
        allFavourites.managedObjectContext.performBlock {
            for i in 0 ..< (favourites?.count ?? 0) {
                let favourite = favourites![i] as! Favourite
                favourite.sortOrder = i
            }
            do { try self.allFavourites.managedObjectContext.save() }
            catch let error as NSError { fatalError("\(error.localizedDescription)\n\(error)") }
            self.dataController.save()
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath)
    {
        switch editingStyle {
        case .Delete:
            if let favourite = allFavourites.fetchedObjects?[indexPath.row] as? Favourite {
                dataController.unfavourite(favourite.naptanId ?? "")
            }
            break
        default:
            break
        }
    }
}

// MARK: - UITableViewDelegate Implementation
extension FavouritesViewController
{
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let favourite = allFavourites.fetchedObjects?[indexPath.row] as? Favourite {
            performSegueWithIdentifier("BusStopDetailSegue", sender: favourite.naptanId)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate Implementation
extension FavouritesViewController: NSFetchedResultsControllerDelegate
{
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        mapFavourites()
        switch type {
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Left)
            refreshProgressViewVisibility()
            break
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            refreshProgressViewVisibility()
            break
        case .Move, .Update:
            break
        }
    }
}

// MARK: - FavouritesDetails Class
private class FavouritesDetails
{
    let stationId: NaptanId
    var stopPointLetter: String
    var stopPointName: String
    var lines: [LineId]
    var stopPoint: StopPoint?
    var arrivals: [BusArrival]
    var favourite: Favourite?
    weak var viewController: FavouritesViewController?
    
    init(stationId: NaptanId, viewController: FavouritesViewController)
    {
        self.stationId = stationId
        arrivals = []
        stopPointName = ""
        stopPointLetter = ""
        lines = []
        self.viewController = viewController
        favourite = viewController.dataController.retrieve(stationId)!
        TFLClient.instance.detailsForBusStop(stationId, resultsProcessor: self)
    }
    
    func refresh()
    {
        TFLClient.instance.busArrivalTimesForStop(stationId, resultsProcessor: self)
    }
    
    private func indexPath() -> NSIndexPath?
    {
        if let index = viewController?.allFavourites.fetchedObjects?
            .indexOf( { ($0 as! Favourite).naptanId == stationId } ) {
            return NSIndexPath(forRow: index, inSection: 0)
        }
        return nil
    }
    
    private func reloadTableView()
    {
        if let indexPath = indexPath() {
            viewController?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        }
    }
}

extension FavouritesDetails: TFLBusStopDetailsProcessor
{
    func handleError(error: NSError)
    {
        NSLog("\(error)")
        Dispatch.mainQueue.async {
            if self.viewController?.presentedViewController == nil {
                let alertVC = UIAlertController(title: "Error Occurred", message: error.localizedDescription,
                    preferredStyle: .Alert)
                alertVC.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                self.viewController?.presentViewController(alertVC, animated: true, completion: nil)
                self.viewController?.timer?.invalidate()
                self.viewController?.timer = nil
                self.viewController?.progressView.hidden = true
            }
        }
    }
    
    func processStopPoint(stopPoint: StopPoint)
    {
        Dispatch.mainQueue.async {
            self.stopPointLetter = stopPoint.stopLetter
            self.stopPointName = stopPoint.name
            self.lines = stopPoint.lines.map { $0.id }
            self.stopPoint = stopPoint
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
            let hiddenRoutes = (self.favourite?.hiddenRoutes?.allObjects ?? []) as! [Route]
            for line in self.lines {
                if hiddenRoutes.contains( { $0.lineId == line } ) { continue }
                if let arrival = arrivals.filter( { $0.lineId == line } ).sort( { $0.ETA < $1.ETA } ).first {
                    self.arrivals.append(arrival)
                }
            }
            self.reloadTableView()
        }
    }
}