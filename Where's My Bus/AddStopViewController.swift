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
    private var visibleStopPoints = [StopPoint]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        map.delegate = self
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
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,
        calloutAccessoryControlTapped control: UIControl)
    {
        if view.rightCalloutAccessoryView == control {
            performSegueWithIdentifier("BusStopDetailSegue", sender: self)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is MKUserLocation { return nil }
        if let view = mapView.dequeueReusableAnnotationViewWithIdentifier("StopPoint") as? MKPinAnnotationView {
            view.annotation = annotation
            return view
        }
        else {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "StopPoint")
            view.pinTintColor = MKPinAnnotationView.redPinColor()
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            return view
        }
        
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        let origin = mapView.visibleMapRect.origin
        let size = mapView.visibleMapRect.size
        let rightMostPoint = MKMapPointMake(origin.x + size.width, origin.y)
        let bottomMostPoint = MKMapPointMake(origin.x, origin.y + size.height)
        let width = Int32(MKMetersBetweenMapPoints(origin, rightMostPoint))
        let height = Int32(MKMetersBetweenMapPoints(origin, bottomMostPoint))
        if width < 2 * TFLBusStopSearchCriteria.MaxRadius ||
           height < 2 * TFLBusStopSearchCriteria.MaxRadius {
            let radius = min(max(width, height), TFLBusStopSearchCriteria.MaxRadius)
            let searchCriteria = TFLBusStopSearchCriteria(centrePoint: mapView.centerCoordinate, radius: radius)
            TFLClient.instance.busStopSearch(searchCriteria, resultsProcessor: self)
            UIView.animateWithDuration(0.3, animations: {
                self.informationalText.alpha = 0.0
                self.informationalOverlay.alpha = 0.0
            }, completion: { isFinished in
                self.informationalOverlay.hidden = true
                self.informationalText.hidden = true
            })
        }
        else {
            UIView.animateWithDuration(0.3, animations: {
                self.informationalText.alpha = 1.0
                self.informationalOverlay.alpha = 0.65
                self.informationalOverlay.hidden = false
                self.informationalText.hidden = false
            })
        }
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

// MARK: - TFLBusStopSearchResultsProcessor Implementation
extension AddStopViewController: TFLBusStopSearchResultsProcessor
{
    func processStopPoints(stopPoints: StopPoints)
    {
        Dispatch.mainQueue.async {
            let newStopPoints = stopPoints.stopPoints.filter { !self.visibleStopPoints.contains($0) }
            let defunctStopPoints = self.visibleStopPoints.filter { !stopPoints.stopPoints.contains($0) }
            self.visibleStopPoints = stopPoints.stopPoints
            let defunctAnnotations = self.map.annotations.filter { an in
                defunctStopPoints.contains { (sp: StopPoint) -> Bool in sp.location == an.coordinate }
            }
            self.map.removeAnnotations(defunctAnnotations)
            self.map.addAnnotations(newStopPoints.map { MKPointAnnotation(stopPoint: $0) })
        }
    }
    
    func handleError(error: NSError)
    {
        NSLog("\(error)")
    }
}

// MARK: - MKPointAnnotation Private Extension
private extension MKPointAnnotation
{
    convenience init(stopPoint: StopPoint)
    {
        self.init()
        self.coordinate = stopPoint.location
        let title: String
        if stopPoint.stopLetter.hasPrefix("-") {
            title = stopPoint.name
        }
        else {
            title = "\(stopPoint.stopLetter) - \(stopPoint.name)"
        }
        self.title = title
        let subtitle = stopPoint.lines.reduce("") { $0.isEmpty ? "\($1.name)" : "\($0), \($1.name)" }
        self.subtitle = subtitle
    }
}

private func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool
{
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}
