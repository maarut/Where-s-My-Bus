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
    var favourite: Favourite?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        NSLog("\(navigationController == nil)")
    }
    
    @IBAction func closeButtonTapped(sender: UIBarButtonItem)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension LineSelectionViewController: UITableViewDelegate
{
    
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
        return 5
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCellWithIdentifier("LineSelection") {
            return cell
        }
        return UITableViewCell()
        
    }
}
