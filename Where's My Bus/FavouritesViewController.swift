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
    fileprivate var doneButton: UIBarButtonItem!
    fileprivate weak var informationOverlay: UIView!
    fileprivate weak var informationText: UILabel!
    
    var dataController: DataController!
    
    fileprivate var allFavourites: NSFetchedResultsController<Favourite>!
    fileprivate var favouritesMap = [NaptanId: FavouritesDetails]()
    fileprivate var timer: Timer?
    fileprivate var arrivalRefreshCounter = 3000
    fileprivate let arrivalRefreshCounterInterval = 3000
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        navigationItem.title = "Favourite Bus Stops"
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 800
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refresh), for: .valueChanged)
        doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
        allFavourites = dataController.allFavourites()
        allFavourites.delegate = self
        do { try allFavourites.performFetch() }
        catch let error as NSError { NSLog("\(error)\n\(error.localizedDescription)") }
    }
    
    override func didMove(toParentViewController parent: UIViewController?)
    {
        if let navigationView = parent?.navigationController?.view {
            addInformationOverlayTo(navigationView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        hideOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        refreshProgressViewVisibility()
        mapFavourites()
        displayOverlayIfNeeded()
        tableView.reloadData()
    }
    
    fileprivate func addInformationOverlayTo(_ superView: UIView)
    {
        let view = UIView()
        let text = UILabel()
        superView.addSubview(view)
        superView.addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        text.text = "Tap the + button to add bus stops to your favourites list."
        text.textColor = UIColor.white
        text.lineBreakMode = .byWordWrapping
        text.textAlignment = .center
        text.numberOfLines = 0
        NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: superView,
                           attribute: .centerX, multiplier: 0.25, constant: 0).isActive = true
        view.heightAnchor.constraint(equalToConstant: 64).isActive = true
        view.centerXAnchor.constraint(equalTo: superView.centerXAnchor).isActive = true
        text.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        text.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        text.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9, constant: 0).isActive = true
        text.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9, constant: 0).isActive = true
        view.backgroundColor = UIColor.darkGray
        view.alpha = 0.65
        view.topAnchor.constraint(//superView.topAnchor, constant: 8).active = true
            equalTo: (navigationController?.navigationBar.bottomAnchor)!, constant: 8).isActive = true
        view.layer.cornerRadius = 10
        informationText = text
        informationOverlay = view
    }
    
    fileprivate func hideOverlay()
    {
        UIView.animate(withDuration: 0.3, animations: {
            self.informationOverlay.alpha = 0
            self.informationText.alpha = 0
        }, completion: { _ in
            self.informationOverlay.isHidden = true
            self.informationText.isHidden = true
        })
    }
    
    fileprivate func displayOverlayIfNeeded()
    {
        guard navigationController?.visibleViewController == parent else { return }
        if self.allFavourites.fetchedObjects?.count ?? 0 == 0 {
            UIView.animate(withDuration: 0.3, animations: {
                self.informationOverlay.isHidden = false
                self.informationText.isHidden = false
                self.informationOverlay.alpha = 0.65
                self.informationText.alpha = 1.0
            }) 
        }
        else {
            hideOverlay()
        }
    }
    
    fileprivate func refreshProgressViewVisibility()
    {
        if allFavourites.fetchedObjects?.count ?? 0 == 0 {
            timer?.invalidate()
            timer = nil
            UIView.animate(withDuration: 0.3, animations: { self.progressView.alpha = 1.0 },
                completion: { _ in self.progressView.isHidden = true; self.progressView.alpha = 0.0 })
        }
        else {
            if !(timer?.isValid ?? false) {
                arrivalRefreshCounter = arrivalRefreshCounterInterval
                timer = Timer.scheduledTimer(timeInterval: 0.01, target: self,
                    selector: #selector(self.timerElapsed(_:)), userInfo: nil, repeats: true)
                UIView.animate(withDuration: 0.3, animations: { self.progressView.isHidden = false }) 
            }
        }
    }
    
    fileprivate func mapFavourites()
    {
        let fetchedObjects = allFavourites.fetchedObjects ?? []
        for favourite in fetchedObjects {
            if let stationId = favourite.stationId {
                if favouritesMap[stationId] == nil {
                    favouritesMap[stationId] = FavouritesDetails(stationId: stationId, viewController: self)
                }
                favouritesMap[stationId]!.refresh()
            }
        }
        for stationId in favouritesMap.keys {
            if !fetchedObjects.contains( where: { $0.stationId == stationId }) {
                favouritesMap[stationId] = nil
            }
        }
    }
    
    fileprivate func configureCell(_ cell: FavouritesCell, with details: FavouritesDetails)
    {
        cell.stopName.text =
            "\(details.stopPointLetter.isEmpty ? "" : "\(details.stopPointLetter) - ")\(details.stopPointName)"
        for i in 0 ..< details.arrivals.count {
            let routeInfo: ETAInformationView
            if i < cell.stackView.arrangedSubviews.count {
                routeInfo = cell.stackView.arrangedSubviews[i] as! ETAInformationView
            }
            else {
                routeInfo = ETAInformationView(frame: CGRect.zero)
                cell.stackView.addArrangedSubview(routeInfo)
            }
            let minutesToArrival = Int(details.arrivals[i].ETA / 60.0)
            routeInfo.route.text = "\(details.arrivals[i].lineName)"
            routeInfo.routeBorder.layer.cornerRadius = 3.0
            routeInfo.towards.text = details.arrivals[i].destination
            if minutesToArrival == 0 { routeInfo.eta.text = "Due" }
            else { routeInfo.eta.text = "\(minutesToArrival) min\(minutesToArrival == 1 ? "" : "s")" }
            routeInfo.isHidden = false
        }
        if details.arrivals.count < cell.stackView.arrangedSubviews.count {
            for i in details.arrivals.count ..< cell.stackView.arrangedSubviews.count {
                cell.stackView.arrangedSubviews[i].isHidden = true
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
    func timerElapsed(_ timer: Timer)
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
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        for detail in favouritesMap.values {
            detail.refresh()
        }
        refreshControl?.endRefreshing()
    }
    
    func doneTapped(_ button: UIBarButtonItem)
    {
        tableView.setEditing(false, animated: true)
        if timer == nil || !timer!.isValid {
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self,
                selector: #selector(self.timerElapsed(_:)), userInfo: nil, repeats: true)
        }
        parent?.navigationItem.setRightBarButton(
            (parent as? FavouritesContainerViewController)?.addStopButton, animated: true)
    }
    
    @IBAction func longPressRecognised(_ sender: UILongPressGestureRecognizer)
    {
        switch sender.state {
        case .ended:
            tableView.setEditing(true, animated: true)
            timer?.invalidate()
            timer = nil
            parent?.navigationItem.setRightBarButton(doneButton, animated: true)
            break
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource Implementation
extension FavouritesViewController
{
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return allFavourites.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Favourite") as? FavouritesCell else {
            fatalError("Could not dequeue cell with identifier \"Favourite\". This should not happen.")
        }
        if let stationId = (allFavourites.fetchedObjects?[indexPath.row])?.stationId,
            let details = favouritesMap[stationId] {
            if !favouritesMap.values.contains( where: { !$0.hasRefreshed } ) {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if timer == nil || !timer!.isValid {
                    timer = Timer.scheduledTimer(timeInterval: 0.01, target: self,
                        selector: #selector(self.timerElapsed(_:)), userInfo: nil, repeats: true)
                }
            }
            configureCell(cell, with: details)
            return cell
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath)
    {
        var favourites = self.allFavourites.fetchedObjects
        if let obj = favourites?.remove(at: sourceIndexPath.row) {
            favourites?.insert(obj, at: destinationIndexPath.row)
        }
        allFavourites.managedObjectContext.perform {
            for i in 0 ..< (favourites?.count ?? 0) {
                let favourite = favourites![i]
                favourite.sortOrder = i as NSNumber?
            }
            do { try self.allFavourites.managedObjectContext.save() }
            catch let error as NSError { fatalError("\(error.localizedDescription)\n\(error)") }
            self.dataController.save()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
        forRowAt indexPath: IndexPath)
    {
        switch editingStyle {
        case .delete:
            if let favourite = allFavourites.fetchedObjects?[indexPath.row] {
                dataController.unfavourite(favourite.stationId ?? "")
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
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let favourite = allFavourites.fetchedObjects?[indexPath.row],
            let parentVC = parent as? FavouritesContainerViewController {
            parentVC.stopPoint = favouritesMap[favourite.stationId!]?.stopPoint
            parentVC.performSegue(withIdentifier: "BusStopDetailSegue", sender: nil)
            hideOverlay()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate Implementation
extension FavouritesViewController: NSFetchedResultsControllerDelegate
{
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any,
        at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        mapFavourites()
        displayOverlayIfNeeded()
        switch type {
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .left)
            refreshProgressViewVisibility()
            break
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
            refreshProgressViewVisibility()
            break
        case .move, .update:
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
    var favourite: Favourite
    var hasRefreshed = false
    weak var viewController: FavouritesViewController?
    
    init(stationId: NaptanId, viewController: FavouritesViewController)
    {
        self.stationId = stationId
        favourite = viewController.dataController.retrieve(stationId)!
        stopPointName = favourite.stopName!
        stopPointLetter = favourite.stopLetter!
        lines = favourite.routes!.allObjects.flatMap { ($0 as! Route).lineId }
        self.viewController = viewController
        arrivals = []
        TFLClient.instance.detailsForBusStop(stationId, resultsProcessor: self)
    }
    
    func refresh()
    {
        hasRefreshed = false
        TFLClient.instance.busArrivalTimesForStop(stationId, resultsProcessor: self)
    }
    
    fileprivate func indexPath() -> IndexPath?
    {
        if let index = viewController?.allFavourites.fetchedObjects?
            .index( where: { $0.stationId == stationId } ) {
            return IndexPath(row: index, section: 0)
        }
        return nil
    }
    
    fileprivate func reloadTableView()
    {
        hasRefreshed = true
        if let indexPath = indexPath() {
            viewController?.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

extension FavouritesDetails: TFLBusStopDetailsProcessor
{
    func handleError(_ error: NSError)
    {
        NSLog("\(error)")
        DispatchQueue.main.async {
            if self.viewController?.presentedViewController == nil {
                let alertVC = UIAlertController(title: "Error Occurred", message: error.localizedDescription,
                    preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.viewController?.present(alertVC, animated: true, completion: nil)
                self.viewController?.timer?.invalidate()
                self.viewController?.timer = nil
                self.viewController?.progressView.isHidden = true
            }
        }
    }
    
    func processStopPoint(_ stopPoint: StopPoint)
    {
        DispatchQueue.main.async {
            self.stopPointLetter = stopPoint.stopLetter
            self.stopPointName = stopPoint.name
            self.lines = stopPoint.lines.map { $0.id }
            self.stopPoint = stopPoint
            if self.favourite.stopLetter != self.stopPointLetter { self.favourite.stopLetter = self.stopPointLetter }
            if self.favourite.stopName != self.stopPointName { self.favourite.stopName = self.stopPointName }
            let currentRoutes = self.favourite.routes!.allObjects.flatMap { ($0 as! Route).lineId }
            if currentRoutes != self.lines {
                for line in stopPoint.lines {
                    if !currentRoutes.contains(line.id) {
                        let route = Route(line: line, context: self.favourite.managedObjectContext!)
                        route.favourite = self.favourite
                        (self.favourite.routes?.mutableCopy() as AnyObject).add(route)
                    }
                }
                for route in self.favourite.routes! {
                    if !self.lines.contains(LineId((route as! Route).lineId!)) {
                        (self.favourite.routes?.mutableCopy() as? NSMutableSet)?.remove(route)
                    }
                }
            }
            self.reloadTableView()
        }
    }
}

extension FavouritesDetails: TFLBusArrivalSearchResultsProcessor
{
    func processResults(_ arrivals: [BusArrival])
    {
        DispatchQueue.main.async {
            self.arrivals = []
            let hiddenRoutes = (self.favourite.routes!.allObjects.filter {
                ($0 as! Route).isHidden?.boolValue ?? false
            }) as! [Route]
            for line in self.lines {
                if hiddenRoutes.contains( where: { $0.lineId == line } ) { continue }
                if let arrival = arrivals.filter( { $0.lineId == line } ).sorted( by: { $0.ETA < $1.ETA } ).first {
                    self.arrivals.append(arrival)
                }
            }
            self.reloadTableView()
        }
    }
}
