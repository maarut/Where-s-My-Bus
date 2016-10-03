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
    
    private var adBannerViewHidden = false
    
    private weak var informationOverlay: UIView!
    private weak var informationText: UILabel!
    
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
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        requestAd()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        switch segue.identifier {
        case .Some("EmbedSegue"):
            let nextVC = segue.destinationViewController as! FavouritesViewController
            nextVC.dataController = dataController
            break
        case .Some("AddStopSegue"):
            (segue.destinationViewController as! SearchStopViewController).dataController = dataController
            break
        case .Some("BusStopDetailSegue"):
            let nextVC = (segue.destinationViewController as! BusStopDetailsContainerViewController)
            nextVC.dataController = dataController
            nextVC.stopPoint = stopPoint
            break
        default:
            break
        }
        
    }
    
    private func requestAd()
    {
        let request = GADRequest()
        request.testDevices = MCConstants.adMobTestDevices() + [kGADSimulatorID]
        adBannerView.loadRequest(request)
    }
}

extension FavouritesContainerViewController: GADBannerViewDelegate
{
    func adViewDidReceiveAd(bannerView: GADBannerView!)
    {
        adBannerViewHidden = false
        Dispatch.mainQueue.async { self.bottomConstraint.constant = 0 }
        Dispatch.mainQueue.after(30 * Int64(NSEC_PER_SEC)) { self.requestAd() }
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!)
    {
        adBannerViewHidden = true
        Dispatch.mainQueue.async { self.bottomConstraint.constant = -bannerView.frame.height }
        Dispatch.mainQueue.after(30 * Int64(NSEC_PER_SEC)) { self.requestAd() }
    }
}
