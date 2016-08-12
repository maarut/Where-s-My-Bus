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
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refresh(control: UIRefreshControl)
    {
        control.endRefreshing()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier {
        case .Some("AddStopSegue"):
            (segue.destinationViewController as! SearchStopViewController).dataController = dataController
            break
        case .Some("BusStopDetailSegue"):
            (segue.destinationViewController as! BusStopDetailsViewController).dataController = dataController
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
            return cell
        }
        return UITableViewCell()
    }
}

// MARK: - UITableViewDelegate Implementation
extension FavouritesViewController
{
}

// MARK: - NSFetchedResultsControllerDelegate Implementation
extension FavouritesViewController: NSFetchedResultsControllerDelegate
{
    
}
