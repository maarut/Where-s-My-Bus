//
//  BusStopDetailsViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 05/08/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit

enum BusStopDetailsSortOrder: Int
{
    case route
    case eta
}

class BusStopDetailsViewController: UITableViewController
{
    var stopPoint: StopPoint?
    var dataController: DataController!
    var sortOrder: BusStopDetailsSortOrder! {
        didSet {
            tableView.reloadData()
        }
    }
    
    fileprivate var arrivals = [BusArrival]()
    fileprivate var timer: Timer?
    fileprivate var arrivalRefreshCounter = 3000
    fileprivate let arrivalRefreshCounterInterval = 3000
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refresh), for: .valueChanged)
        if let stopPoint = stopPoint {
            TFLClient.instance.busArrivalTimesForStop(stopPoint.id, resultsProcessor: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timerElapsed(_:)),
                userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
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
        if progressView.isHidden {
            progressView.isHidden = false
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timerElapsed(_:)),
                userInfo: nil, repeats: true)
        }
        arrivalRefreshCounter = arrivalRefreshCounterInterval
        progressView.progress = 1.0
        if let stopPoint = stopPoint {
            TFLClient.instance.busArrivalTimesForStop(stopPoint.id , resultsProcessor: self)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }
}

// MARK: - UITableViewDataSource Implementation
extension BusStopDetailsViewController
{
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch sortOrder! {
        case .route:
            if let lineId = stopPoint?.lines[section].id {
                let lineIdArrivals = arrivals.filter { $0.lineId == lineId }
                return lineIdArrivals.count
            }
            break
        case .eta:
            return arrivals.count
        }
        return 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        switch sortOrder! {
        case .eta:
            return 1
        case .route:
            return stopPoint?.lines.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return sortOrder == .eta ? nil : stopPoint?.lines[section].name
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier()) as? BusArrivalDetailsCell,
            let arrival = arrival(indexPath) {
            let minutes = Int(arrival.ETA / 60.0)
            if minutes == 0 { cell.eta.text = "Due" }
            else { cell.eta.text = "\(minutes) min\(minutes == 1 ? "" : "s")" }
            cell.direction.text = arrival.destination
            cell.numberPlate.text = arrival.numberPlate
            cell.numberPlateBorder.layer.cornerRadius = 3.0
            cell.numberPlateBorder.layer.borderWidth = 1.0
            configure(cell, with: arrival.lineName)
            return cell
        }
        return UITableViewCell()
    }
    
    fileprivate func identifier() -> String
    {
        switch sortOrder! {
        case .eta:      return "eta"
        case .route:    return "route"
        }
    }
    
    fileprivate func configure(_ cell: BusArrivalDetailsCell, with arrival: String)
    {
        switch sortOrder! {
        case .eta:
            cell.route.text = arrival
            cell.routeBorder.layer.cornerRadius = 3.0
            break
        case .route:
            break
        }
    }
    
    fileprivate func arrival(_ indexPath: IndexPath) -> BusArrival?
    {
        switch sortOrder! {
        case .eta:
            return arrivals.sorted { $0.ETA < $1.ETA }[indexPath.row]
        case .route:
            if let line = stopPoint?.lines[indexPath.section] {
                return arrivals.filter { $0.lineId == line.id }[indexPath.row]
            }
        }
        return nil
    }
}

// MARK: - TFLBusArrivalSearchResultsProcessor Implementation
extension BusStopDetailsViewController: TFLBusArrivalSearchResultsProcessor
{
    func handle(error: NSError)
    {
        NSLog("\(error)")
        DispatchQueue.main.async {
            if self.presentedViewController != nil { return }
            let alertVC = UIAlertController(title: "Error Occurred", message: error.localizedDescription,
                preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
            self.timer?.invalidate()
            self.timer = nil
            self.progressView.isHidden = true
        }
    }
    
    func process(arrivals: [BusArrival])
    {
        DispatchQueue.main.async {
            self.arrivals = arrivals
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
}
