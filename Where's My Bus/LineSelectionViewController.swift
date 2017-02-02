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
    
    fileprivate var favourite: Favourite!
    fileprivate var hiddenRoutes = [LineId]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let favourite = dataController.retrieve(stopPoint.id)?.objectID {
            self.favourite = dataController.mainThreadContext.object(with: favourite) as? Favourite
        }
        hiddenRoutes = self.favourite.routes?.flatMap {
            let route = $0 as! Route
            return route.isHidden!.boolValue ? LineId(route.lineId!) : nil
        } ?? []
    }
    
    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func switchToggled(_ toggle: UISwitch)
    {
        let route = stopPoint.lines[toggle.tag]
        dataController.toggleHiddenLine(route, for: favourite)
        if toggle.isOn {
            if let index = hiddenRoutes.index(of: route.id) { hiddenRoutes.remove(at: index) }
        }
        else {
            hiddenRoutes.append(route.id)
        }
    }
}

extension LineSelectionViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if section != 0 { return nil }
        return "Select the routes that you would like to have visible in the Favourites screen."
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let cell = tableView.cellForRow(at: indexPath) as? LineSelectionCell {
            cell.toggle.setOn(!cell.toggle.isOn, animated: true)
        }
    }
}

extension LineSelectionViewController: UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return stopPoint?.lines.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LineSelection") as! LineSelectionCell
        let route = stopPoint.lines[indexPath.row]
        cell.route.text = "\(route.name)"
        cell.toggle.setOn(!hiddenRoutes.contains(route.id), animated: false)
        cell.toggle.tag = indexPath.row
        return cell
        
    }
}
