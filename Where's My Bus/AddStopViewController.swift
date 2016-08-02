//
//  AddStopViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 25/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class AddStopViewController: UIViewController
{
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var informationalOverlay: UIView!
    @IBOutlet weak var informationalText: UILabel!
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationServices()
        informationalOverlay.layer.cornerRadius = 10.0
        switch CLLocationManager.authorizationStatus()
        {
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .Denied:
           promptForLocationServicesDenied()
            break
        case .Restricted:
            let alertVC = UIAlertController(title: "Location Services Restricted",
                message: "Please speak to your device manager to enable location services to automatically find " +
                    "bus stops near you.",
                preferredStyle: .Alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .Cancel,
                handler: { _ in self.dismissViewControllerAnimated(true, completion: nil) } ))
            presentViewController(alertVC, animated: true, completion: nil)
            break
        default:
            break
        }
 
    }
 
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        locationManager.requestLocation()

    }
}

// MARK: - Private Functions
private extension AddStopViewController
{
    func promptForLocationServicesDenied()
    {
        let alertVC = UIAlertController(title: "Location Services Denied",
            message: "Please enable location services to automatically find bus stops near you.",
            preferredStyle: .Alert)
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .Cancel,
            handler: { _ in self.dismissViewControllerAnimated(true, completion: nil) } ))
        alertVC.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { _ in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        presentViewController(alertVC, animated: true, completion: nil)
    }
    
    func checkLocationServices()
    {
        if !CLLocationManager.locationServicesEnabled() {
            let alertVC = UIAlertController(title: "Location Services Disabled",
                message: "Please enable location services to automatically find bus stops near you.",
                preferredStyle: .Alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .Cancel,
                handler: { _ in self.dismissViewControllerAnimated(true, completion: nil) } ))
            alertVC.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { _ in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            }))
            presentViewController(alertVC, animated: true, completion: nil)
        }
    }
}

// MARK: - MKMapViewDelegate Implementation
extension AddStopViewController: MKMapViewDelegate
{
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        
    }
}

// MARK: - CLLocationManagerDelegate Implementation
extension AddStopViewController: CLLocationManagerDelegate
{
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let location = locations.last {
            let distance: CLLocationDistance
            if location.horizontalAccuracy < 500 { distance = 1000.0 }
            else { distance = 2 * location.horizontalAccuracy }
            let region = MKCoordinateRegionMakeWithDistance(location.coordinate, distance, distance)
            map.setRegion(region, animated: true)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        switch error.code {
        case CLError.Denied.rawValue:
            NSLog("Location services denied")
            locationManager.stopUpdatingLocation()
            promptForLocationServicesDenied()
            break
        case CLError.LocationUnknown.rawValue:
            NSLog("Unable to determine location. Will try again later.")
            break
        default:
            break
        }
        NSLog("\(error.localizedDescription)\n\(error)")
    }
}
