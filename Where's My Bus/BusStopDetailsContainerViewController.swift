//
//  BusStopDetailsContainerViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 15/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

class BusStopDetailsContainerViewController: UIViewController
{
    var stopPoint: StopPoint?
    var stationId: NaptanId?
    var dataController: DataController!
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    
    private var favouritedButton: UIBarButtonItem!
    private var addToFavouriteButton: UIBarButtonItem!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        favouritedButton = UIBarButtonItem(image: FavouritesStar.get(.Filled),
            style: .Plain, target: self, action: #selector(toggleFavourite(_:)))
        addToFavouriteButton = UIBarButtonItem(image: FavouritesStar.get(.Empty),
            style: .Plain, target: self, action: #selector(toggleFavourite(_:)))
        if let stopPoint = stopPoint {
            addItemToToolbar(dataController.isFavourite(stopPoint.id) ? favouritedButton : addToFavouriteButton)
            updateNavigationItemTitle(stopPoint)
        }
        else if let stationId = stationId {
            addItemToToolbar(dataController.isFavourite(stationId) ? favouritedButton : addToFavouriteButton)
        }
        var items = toolbar.items
        items?[1] = UIBarButtonItem(image: SortOrderIcon.get(), style: .Plain, target: self,
            action: #selector(sortButtonTapped(_:)))
        toolbar.setItems(items, animated: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "EmbedSegue" {
            let nextVC = segue.destinationViewController as! BusStopDetailsViewController
            nextVC.dataController = dataController
            nextVC.stationId = stationId
            nextVC.stopPoint = stopPoint
            nextVC.sortOrder = retrieveSortOrder()
        }
    }
    
    func toggleFavourite(control: UIBarButtonItem)
    {
        if let stationId = stationId ?? stopPoint?.id {
            var items = toolbar.items
            if dataController.isFavourite(stationId) {
                dataController.unfavourite(stationId)
                items?[3] = addToFavouriteButton
            }
            else {
                dataController.favourite(stationId)
                items?[3] = favouritedButton
            }
            toolbar.setItems(items, animated: false)
        }
    }
    
    func updateNavigationItemTitle(stopPoint: StopPoint)
    {
        Dispatch.mainQueue.async {
            self.navigationItem.title = stopPoint.stopLetter.isEmpty ? stopPoint.name : "Stop \(stopPoint.stopLetter)"
        }
    }
    
}

// MARK: - IBActions
extension BusStopDetailsContainerViewController
{
    @IBAction func sortButtonTapped(button: UIBarButtonItem)
    {
        let actionSheet = UIAlertController(title: "Sort Order",
            message: "Select a criteria to sort by.", preferredStyle: .ActionSheet)
        let route = UIAlertAction(title: "Route", style: .Default, handler: { _ in self.implementSortOrder(.Route) })
        let eta = UIAlertAction(title: "ETA", style: .Default, handler: { _ in self.implementSortOrder(.ETA) })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        [route, eta, cancel].forEach { actionSheet.addAction($0) }
        presentViewController(actionSheet, animated: true, completion: nil)
    }
}

// MARK: - Private Functions
private extension BusStopDetailsContainerViewController
{
    func addItemToToolbar(item: UIBarButtonItem)
    {
        var currentToolbarItems = toolbar.items
        currentToolbarItems?.append(item)
        currentToolbarItems?.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))
        toolbar.setItems(currentToolbarItems, animated: false)
    }
    
    func implementSortOrder(order: BusStopDetailsSortOrder)
    {
        if let childVC = childViewControllers.first as? BusStopDetailsViewController {
            childVC.sortOrder = order
            saveSortOrder(order)
        }
    }
    
    func retrieveSortOrder() -> BusStopDetailsSortOrder
    {
        if let bundleId = NSBundle.mainBundle().bundleIdentifier {
            let sortOrderRaw = NSUserDefaults.standardUserDefaults().integerForKey("\(bundleId).sortOrder")
            return BusStopDetailsSortOrder(rawValue: sortOrderRaw) ?? .Route
        }
        return .Route
    }
    
    func saveSortOrder(sortOrder: BusStopDetailsSortOrder)
    {
        if let bundleId = NSBundle.mainBundle().bundleIdentifier {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setInteger(sortOrder.rawValue, forKey: "\(bundleId).sortOrder")
            userDefaults.synchronize()
        }
    }
    
}