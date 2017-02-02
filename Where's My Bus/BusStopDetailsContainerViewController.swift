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
    var dataController: DataController!
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var sortButton: UIBarButtonItem!
    @IBOutlet var editButton: UIBarButtonItem!
    
    fileprivate var favouritedButton: UIBarButtonItem!
    fileprivate var addToFavouriteButton: UIBarButtonItem!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        favouritedButton = UIBarButtonItem(image: FavouritesStar.get(.filled),
            style: .plain, target: self, action: #selector(toggleFavourite(_:)))
        addToFavouriteButton = UIBarButtonItem(image: FavouritesStar.get(.empty),
            style: .plain, target: self, action: #selector(toggleFavourite(_:)))
        if let stopPoint = stopPoint {
            if dataController.isFavourite(stopPoint.id) {
                navigationItem.setRightBarButton(editButton, animated: true)
                addItemToToolbar(favouritedButton)
            }
            else {
                navigationItem.setRightBarButton(nil, animated: true)
                addItemToToolbar(addToFavouriteButton)
            }
            updateNavigationItemTitle(stopPoint)
        }
        var items = toolbar.items
        items?[1] = UIBarButtonItem(image: SortOrderIcon.get(), style: .plain, target: self,
            action: #selector(sortButtonTapped(_:)))
        toolbar.setItems(items, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier ?? "" {
        case "EmbedSegue":
            let nextVC = segue.destination as! BusStopDetailsViewController
            nextVC.dataController = dataController
            nextVC.stopPoint = stopPoint
            nextVC.sortOrder = retrieveSortOrder()
            break
        case "LineSelectionSegue":
            let nextVC = segue.destination as! LineSelectionViewController
            nextVC.dataController = dataController
            nextVC.stopPoint = stopPoint
            break
        default:
            break
        }
        
    }
    
    func toggleFavourite(_ control: UIBarButtonItem)
    {
        if let stopPoint = stopPoint {
            var items = toolbar.items
            if dataController.isFavourite(stopPoint.id) {
                dataController.unfavourite(stopPoint.id)
                items?[3] = addToFavouriteButton
                navigationItem.setRightBarButton(nil, animated: true)
            }
            else {
                dataController.favourite(stopPoint)
                items?[3] = favouritedButton
                navigationItem.setRightBarButton(editButton, animated: true)
            }
            toolbar.setItems(items, animated: false)
        }
    }
    
    func updateNavigationItemTitle(_ stopPoint: StopPoint)
    {
        DispatchQueue.main.async {
            self.navigationItem.title = stopPoint.stopLetter.isEmpty ? stopPoint.name : "Stop \(stopPoint.stopLetter)"
        }
    }
    
}

// MARK: - IBActions
extension BusStopDetailsContainerViewController
{
    @IBAction func sortButtonTapped(_ button: UIBarButtonItem)
    {
        let actionSheet = UIAlertController(title: "Sort Order",
            message: "Select a criteria to sort by.", preferredStyle: .actionSheet)
        let route = UIAlertAction(title: "Route", style: .default, handler: { _ in self.implementSortOrder(.route) })
        let eta = UIAlertAction(title: "ETA", style: .default, handler: { _ in self.implementSortOrder(.eta) })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        [route, eta, cancel].forEach { actionSheet.addAction($0) }
        present(actionSheet, animated: true, completion: nil)
    }
}

// MARK: - Private Functions
private extension BusStopDetailsContainerViewController
{
    func addItemToToolbar(_ item: UIBarButtonItem)
    {
        var currentToolbarItems = toolbar.items
        currentToolbarItems?.append(item)
        currentToolbarItems?.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        toolbar.setItems(currentToolbarItems, animated: false)
    }
    
    func implementSortOrder(_ order: BusStopDetailsSortOrder)
    {
        if let childVC = childViewControllers.first as? BusStopDetailsViewController {
            childVC.sortOrder = order
            saveSortOrder(order)
        }
    }
    
    func retrieveSortOrder() -> BusStopDetailsSortOrder
    {
        if let bundleId = Bundle.main.bundleIdentifier {
            let sortOrderRaw = UserDefaults.standard.integer(forKey: "\(bundleId).sortOrder")
            return BusStopDetailsSortOrder(rawValue: sortOrderRaw) ?? .route
        }
        return .route
    }
    
    func saveSortOrder(_ sortOrder: BusStopDetailsSortOrder)
    {
        if let bundleId = Bundle.main.bundleIdentifier {
            let userDefaults = UserDefaults.standard
            userDefaults.set(sortOrder.rawValue, forKey: "\(bundleId).sortOrder")
            userDefaults.synchronize()
        }
    }
    
}
