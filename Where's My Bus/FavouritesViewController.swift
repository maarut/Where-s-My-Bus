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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
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
    }
    
    func refresh(control: UIRefreshControl)
    {
        control.endRefreshing()
        tableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier {
        case .Some("AddStopSegue"):
            (segue.destinationViewController as! SearchStopViewController).dataController = dataController
            break
        case .Some("BusStopDetailSegue"):
            let nextVC = (segue.destinationViewController as! BusStopDetailsViewController)
            nextVC.dataController = dataController
            nextVC.stationId = (sender as? Favourite)?.naptanId
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
        if let cell = tableView.dequeueReusableCellWithIdentifier("Favourite") {
            cell.detailTextLabel?.text = "The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog."
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
        tableView.reloadData()
    }
}