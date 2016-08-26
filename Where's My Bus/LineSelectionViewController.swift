//
//  LineSelectionViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 24/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

class LineSelectionViewController: UIViewController
{
    var dataController: DataController!
    var stopPoint: StopPoint!
    
    private var favourite: Favourite!
    private var hiddenRoutes = [LineId]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let favourite = dataController.retrieve(stopPoint.id)?.objectID {
            self.favourite = dataController.mainThreadContext.objectWithID(favourite) as? Favourite
        }
        hiddenRoutes = self.favourite.routes?.flatMap {
            let route = $0 as! Route
            return route.isHidden!.boolValue ? LineId(route.lineId!) : nil
        } ?? []
    }
    
    @IBAction func closeButtonTapped(sender: UIBarButtonItem)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func switchToggled(toggle: UISwitch)
    {
        let route = stopPoint.lines[toggle.tag]
        dataController.toggleHiddenLine(route, for: favourite)
        if toggle.on {
            if let index = hiddenRoutes.indexOf(route.id) { hiddenRoutes.removeAtIndex(index) }
        }
        else {
            hiddenRoutes.append(route.id)
        }
    }
}

extension LineSelectionViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if section != 0 { return nil }
        return "Select the routes that you would like to have visible in the Favourites screen."
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? LineSelectionCell {
            cell.toggle.setOn(!cell.toggle.on, animated: true)
        }
    }
}

extension LineSelectionViewController: UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return stopPoint?.lines.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("LineSelection") as! LineSelectionCell
        let route = stopPoint.lines[indexPath.row]
        cell.route.text = "\(route.name)"
        cell.toggle.setOn(!hiddenRoutes.contains(route.id), animated: false)
        cell.toggle.tag = indexPath.row
        return cell
        
    }
}
