//
//  SearchStopViewController.swift
//  Where's My Bus
//
//  Created by Maarut Chandegra on 25/07/2016.
//  Copyright © 2016 Maarut Chandegra. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import CoreData

class SearchStopViewController: UIViewController
{
    var dataController: DataController!
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var informationalOverlay: UIView!
    @IBOutlet weak var informationalText: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    
    private let locationManager = CLLocationManager()
    private var normalNearMeBarButton: UIBarButtonItem!
    private var pressedNearMeBarButton: UIBarButtonItem!
    private var allFavourites: NSFetchedResultsController!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        allFavourites = dataController.allFavourites()
        allFavourites.delegate = self
        do {
            try allFavourites.performFetch()
        }
        catch let error as NSError {
            NSLog("\(error)\n\(error.localizedDescription)")
        }
        informationalOverlay.layer.cornerRadius = 10.0
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authoriseLocationServices()
        normalNearMeBarButton = UIBarButtonItem(image: NearMeArrow.get(state: .Normal), style: .Plain,
            target: self, action: #selector(nearMePressed(_:)))
        pressedNearMeBarButton = UIBarButtonItem(image: NearMeArrow.get(state: .Pressed), style: .Plain,
            target: self, action: #selector(nearMePressed(_:)))
        resetToolbar()
        locationManager.requestLocation()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        checkLocationServices()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "BusStopDetailSegue" {
            let annotation = sender as! BusStopAnnotation
            let destinationVC = segue.destinationViewController as! BusStopDetailsContainerViewController
            destinationVC.stopPoint = annotation.stopPoint
            destinationVC.dataController = dataController
        }
    }
}

// MARK: - IBActions
extension SearchStopViewController
{
    func nearMePressed(sender: UIBarButtonItem)
    {
        switch sender {
        case normalNearMeBarButton:
            locationManager.requestLocation()
            toolbar.setItems([pressedNearMeBarButton], animated: true)
            break
        case pressedNearMeBarButton:
            locationManager.stopUpdatingLocation()
            resetToolbar()
            break
        default:
            break
        }
    }
}

// MARK: - Private Functions
private extension SearchStopViewController
{
    func authoriseLocationServices()
    {
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
    
    func resetToolbar()
    {
        self.toolbar.setItems([self.normalNearMeBarButton], animated: true)
    }
    
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
extension SearchStopViewController: MKMapViewDelegate
{
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,
        calloutAccessoryControlTapped control: UIControl)
    {
        if let annotation = view.annotation as? BusStopAnnotation {
            if view.rightCalloutAccessoryView == control {
                performSegueWithIdentifier("BusStopDetailSegue", sender: annotation)
            }
            else if view.leftCalloutAccessoryView == control {
                if dataController.isFavourite(annotation.stopPoint.id) {
                    dataController.unfavourite(annotation.stopPoint.id)
                }
                else {
                    dataController.favourite(annotation.stopPoint.id)
                }
            }
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is MKUserLocation { return nil }
        let image = dataController!.isFavourite((annotation as! BusStopAnnotation).stopPoint.id) ?
            FavouritesStar.get(.Filled) :
            FavouritesStar.get(.Empty)
        if let view = mapView.dequeueReusableAnnotationViewWithIdentifier("StopPoint") as? MKPinAnnotationView {
            view.annotation = annotation
            (view.leftCalloutAccessoryView as! UIButton).setImage(image, forState: .Normal)
            return view
        }
        else {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "StopPoint")
            view.pinTintColor = MKPinAnnotationView.redPinColor()
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            var frame = view.rightCalloutAccessoryView!.frame
            frame.origin = CGPointZero
            let button = UIButton(type: .Custom)
            button.frame = frame
            button.setImage(image, forState: .Normal)
            view.leftCalloutAccessoryView = button
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
        if width < 2 * TFLBusStopSearchCriteria.MaxRadius &&
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
extension SearchStopViewController: CLLocationManagerDelegate
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
        resetToolbar()
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
            resetToolbar()
            break
        default:
            break
        }
        NSLog("\(error.localizedDescription)\n\(error)")
    }
}

// MARK: - TFLBusStopSearchResultsProcessor Implementation
extension SearchStopViewController: TFLBusStopSearchResultsProcessor
{
    func processStopPoints(stopPoints: StopPoints)
    {
        Dispatch.mainQueue.async {
            let annotations = self.map.annotations.flatMap { $0 as? BusStopAnnotation }
            let newStopPoints = stopPoints.stopPoints.filter { sp in
                !annotations.contains { sp == $0.stopPoint }
            }
            let defunctAnnotations = annotations.filter { !stopPoints.stopPoints.contains($0.stopPoint) }
            self.map.removeAnnotations(defunctAnnotations)
            self.map.addAnnotations(newStopPoints.map { BusStopAnnotation(stopPoint: $0) })
        }
    }
    
    func handleError(error: NSError)
    {
        NSLog("\(error)\n\(error.localizedDescription)")
    }
}

// MARKY - NSFetchedResultsControllerDelegate Implementation
extension SearchStopViewController: NSFetchedResultsControllerDelegate
{
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        Dispatch.mainQueue.async {
            let busStops = self.map.annotations.flatMap { $0 as? BusStopAnnotation }
            for stop in busStops {
                let view = self.map.viewForAnnotation(stop)
                (view?.leftCalloutAccessoryView as! UIButton).setImage(FavouritesStar.get(.Empty), forState: .Normal)
            }
            let favourites = controller.fetchedObjects as! [Favourite]
            for favourite in favourites {
                let annotations = busStops.filter { $0.stopPoint.id == favourite.naptanId }
                if let annotation = annotations.first, let view = self.map.viewForAnnotation(annotation) {
                    (view.leftCalloutAccessoryView as! UIButton).setImage(
                        FavouritesStar.get(.Filled), forState: .Normal)
                }
            }
        }
    }
}

// MARK: - BusStopAnnocation Private Class
private class BusStopAnnotation: NSObject, MKAnnotation
{
    private (set) var stopPoint: StopPoint
    @objc var coordinate: CLLocationCoordinate2D {
        get {
            return stopPoint.location
        }
    }
    
    @objc private (set) var title: String?
    @objc private (set) var subtitle: String?
    
    init(stopPoint: StopPoint)
    {
        self.stopPoint = stopPoint
        self.title = stopPoint.stopLetter.isEmpty ? stopPoint.name :
            "\(stopPoint.stopLetter) - \(stopPoint.name)"
        let subtitle = stopPoint.lines.reduce("") { $0.isEmpty ? "\($1.name)" : "\($0), \($1.name)" }
        self.subtitle = subtitle
        super.init()
    }
}

private func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool
{
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}
