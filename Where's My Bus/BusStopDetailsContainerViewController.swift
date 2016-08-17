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
    
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var routeButton: UITabBarItem!
    @IBOutlet weak var etaButton: UITabBarItem!
    
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
            navigationItem.rightBarButtonItem = dataController.isFavourite(stopPoint.id) ?
                favouritedButton :
                addToFavouriteButton
            updateNavigationItemTitle(stopPoint)
        }
        else if let stationId = stationId {
            navigationItem.rightBarButtonItem = dataController.isFavourite(stationId) ?
                favouritedButton :
                addToFavouriteButton
        }
        routeButton.title = "↓Route"
        etaButton.title = "↓ETA"
        switch retrieveSortOrder() {
        case .Route:
            tabBar.selectedItem = routeButton
            break
        case .ETA:
            tabBar.selectedItem = etaButton
            break
        }
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
            if dataController.isFavourite(stationId) {
                dataController.unfavourite(stationId)
                navigationItem.rightBarButtonItem = addToFavouriteButton
            }
            else {
                dataController.favourite(stationId)
                navigationItem.rightBarButtonItem = favouritedButton
            }
        }
    }
    
    func updateNavigationItemTitle(stopPoint: StopPoint)
    {
        navigationItem.title = stopPoint.stopLetter.isEmpty ? stopPoint.name : "Stop \(stopPoint.stopLetter)"
    }
    
    private func retrieveSortOrder() -> BusStopDetailsSortOrder
    {
        if let bundleId = NSBundle.mainBundle().bundleIdentifier {
            let sortOrderRaw = NSUserDefaults.standardUserDefaults().integerForKey("\(bundleId).sortOrder")
            return BusStopDetailsSortOrder(rawValue: sortOrderRaw) ?? .Route
        }
        return .Route
    }
    
    private func saveSortOrder(sortOrder: BusStopDetailsSortOrder)
    {
        if let bundleId = NSBundle.mainBundle().bundleIdentifier {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            userDefaults.setInteger(sortOrder.rawValue, forKey: "\(bundleId).sortOrder")
            userDefaults.synchronize()
        }
    }
}

extension BusStopDetailsContainerViewController: UITabBarDelegate
{
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem)
    {
        tabBar.selectedItem = item
        if let childVC = childViewControllers.first as? BusStopDetailsViewController {
            let sortOrder: BusStopDetailsSortOrder
            switch item {
            case etaButton:
                sortOrder = .ETA
                break
            default:
                sortOrder = .Route
            }
            childVC.sortOrder = sortOrder
            saveSortOrder(sortOrder)
        }
    }
}