//
//  FavouritesContainerViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 22/09/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit
import GoogleMobileAds

class FavouritesContainerViewController: UIViewController
{
    var dataController: DataController!
    var stopPoint: StopPoint?
    
    fileprivate weak var informationOverlay: UIView!
    fileprivate weak var informationText: UILabel!
    
    @IBOutlet weak var addStopButton: UIBarButtonItem!
    @IBOutlet weak var adBannerView: GADBannerView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        adBannerView.delegate = self
        adBannerView.adUnitID = kAdMobAdUnitId
        adBannerView.rootViewController = self
        adBannerView.adSize = kGADAdSizeBanner
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        requestAd()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier {
        case .some("EmbedSegue"):
            let nextVC = segue.destination as! FavouritesViewController
            nextVC.dataController = dataController
            break
        case .some("AddStopSegue"):
            (segue.destination as! SearchStopViewController).dataController = dataController
            break
        case .some("BusStopDetailSegue"):
            let nextVC = (segue.destination as! BusStopDetailsContainerViewController)
            nextVC.dataController = dataController
            nextVC.stopPoint = stopPoint
            break
        default:
            break
        }
        
    }
    
    fileprivate func requestAd()
    {
        let request = GADRequest()
        request.testDevices = MCConstants.adMobTestDevices() + [kGADSimulatorID]
        adBannerView.load(request)
    }
}

extension FavouritesContainerViewController: GADBannerViewDelegate
{
    func adViewDidReceiveAd(_ bannerView: GADBannerView!)
    {
        DispatchQueue.main.async { self.bottomConstraint.constant = 0 }
        let time = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 30 * NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) { self.requestAd() }
    }
    
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!)
    {
        DispatchQueue.main.async { self.bottomConstraint.constant = -bannerView.frame.height }
        let time = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 30 * NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) { self.requestAd() }
    }
}
