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
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var normalNearMeBarButton: UIBarButtonItem!
    fileprivate var pressedNearMeBarButton: UIBarButtonItem!
    fileprivate var allFavourites: NSFetchedResultsController<Favourite>!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        allFavourites = dataController.allFavourites()
        allFavourites.delegate = self
        do {
            try allFavourites.performFetch()
        }
        catch let error as NSError {
            handle(error: error)
        }
        informationalOverlay.layer.cornerRadius = 10.0
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        normalNearMeBarButton = UIBarButtonItem(image: NearMeArrow.get(state: .normal), style: .plain,
            target: self, action: #selector(nearMePressed(_:)))
        pressedNearMeBarButton = UIBarButtonItem(image: NearMeArrow.get(state: .pressed), style: .plain,
            target: self, action: #selector(nearMePressed(_:)))
        resetToolbar()
        checkLocationServices()
        locationManager.requestLocation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "BusStopDetailSegue" {
            let annotation = sender as! BusStopAnnotation
            let destinationVC = segue.destination as! BusStopDetailsContainerViewController
            destinationVC.stopPoint = annotation.stopPoint
            destinationVC.dataController = dataController
        }
    }
}

// MARK: - IBActions
extension SearchStopViewController
{
    func nearMePressed(_ sender: UIBarButtonItem)
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
    
    func detailButtonPressed(_ sender: UIButton)
    {
        if let annotation = (sender as? BusStopDetailButton)?.annotation as? BusStopAnnotation {
            performSegue(withIdentifier: "BusStopDetailSegue", sender: annotation)
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
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .denied:
            promptForLocationServicesDenied()
            break
        case .restricted:
            let alertVC = UIAlertController(title: "Location Services Restricted",
                message: "Please speak to your device manager to enable location services to automatically find " +
                    "bus stops near you.",
                preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel,
                handler: { _ in self.dismiss(animated: true, completion: nil) } ))
            present(alertVC, animated: true, completion: nil)
            break
        default:
            break
        }
    }
    
    func resetToolbar()
    {
        switch CLLocationManager.authorizationStatus() {
        case .denied, .restricted:
            toolbar.setItems([], animated: true)
            break
        default:
            toolbar.setItems([normalNearMeBarButton], animated: true)
            break
        }
    }
    
    func promptForLocationServicesDenied()
    {
        let alertVC = UIAlertController(title: "Location Services Denied",
            message: "Please enable location services to automatically find bus stops near you.",
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel,
            handler: { _ in self.dismiss(animated: true, completion: nil) } ))
        alertVC.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        }))
        present(alertVC, animated: true, completion: nil)
    }
    
    func checkLocationServices()
    {
        if !CLLocationManager.locationServicesEnabled() {
            let alertVC = UIAlertController(title: "Location Services Disabled",
                message: "Please enable location services to automatically find bus stops near you.",
                preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel,
                handler: { _ in self.dismiss(animated: true, completion: nil) } ))
            alertVC.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            present(alertVC, animated: true, completion: nil)
        }
        else {
            authoriseLocationServices()
        }
    }
}

// MARK: - MKMapViewDelegate Implementation
extension SearchStopViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
        calloutAccessoryControlTapped control: UIControl)
    {
        if let annotation = view.annotation as? BusStopAnnotation {
            if view.leftCalloutAccessoryView == control {
                if dataController.isFavourite(annotation.stopPoint.id) {
                    dataController.unfavourite(annotation.stopPoint.id)
                }
                else {
                    dataController.favourite(annotation.stopPoint)
                }
            }
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is MKUserLocation { return nil }
        let image = dataController!.isFavourite((annotation as! BusStopAnnotation).stopPoint.id) ?
            FavouritesStar.get(.filled) :
            FavouritesStar.get(.empty)
        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: "StopPoint") as? MKPinAnnotationView {
            view.annotation = annotation
            if let rightCallout = view.rightCalloutAccessoryView as? BusStopDetailsButtonWithDirectionView,
                let detailButton = rightCallout.detailButton as? BusStopDetailButton {
                detailButton.annotation = annotation
            }
            (view.leftCalloutAccessoryView as! UIButton).setImage(image, for: UIControlState())
            return view
        }
        else {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "StopPoint")
            view.pinTintColor = MKPinAnnotationView.redPinColor()
            view.canShowCallout = true
            let detailButton =  BusStopDetailButton(type: .detailDisclosure)
            detailButton.addTarget(self, action: #selector(detailButtonPressed(_:)), for: .touchUpInside)
            detailButton.annotation = annotation
            let button = UIButton(type: .custom)
            var buttonFrame = detailButton.frame
            buttonFrame.origin = CGPoint.zero
            button.frame = buttonFrame
            button.setImage(image, for: UIControlState())
            view.leftCalloutAccessoryView = button
            var outerFrame = detailButton.frame
            outerFrame.size.width = 2 * outerFrame.size.width + 8
            let outerView = BusStopDetailsButtonWithDirectionView(frame: outerFrame)
            let direction = UILabel(frame: buttonFrame)
            direction.text = "↑"
            direction.textColor = UIColor(hexValue: 0xA1002C)
            direction.textAlignment = .center
            outerView.direction = direction
            outerView.addSubview(direction)
            outerView.detailButton = detailButton
            outerView.addSubview(detailButton)
            detailButton.frame.origin.x += button.frame.width + 8
            view.rightCalloutAccessoryView = outerView
            return view
        }
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
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
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            UIView.animate(withDuration: 0.3, animations: {
                self.informationalText.alpha = 0.0
                self.informationalOverlay.alpha = 0.0
            }, completion: { isFinished in
                self.informationalOverlay.isHidden = true
                self.informationalText.isHidden = true
            })
        }
        else {
            UIView.animate(withDuration: 0.3, animations: {
                self.informationalText.alpha = 1.0
                self.informationalOverlay.alpha = 0.65
                self.informationalOverlay.isHidden = false
                self.informationalText.isHidden = false
            })
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        TFLClient.instance.busArrivalTimesForStop((view.annotation as! BusStopAnnotation).stopPoint.id,
            resultsProcessor: self)
    }
}

extension SearchStopViewController: TFLBusArrivalSearchResultsProcessor
{
    func process(arrivals: [BusArrival])
    {
        DispatchQueue.main.async {
            if let bearing = arrivals.first?.bearing,
                let annotation = self.map.selectedAnnotations.first,
                let view = self.map.view(for: annotation) as? MKPinAnnotationView,
                let directionView = view.rightCalloutAccessoryView as? BusStopDetailsButtonWithDirectionView {
                let bearingRad = bearing / 360.0 * 2 * M_PI
                let xfrm = CGAffineTransform.identity.rotated(by: CGFloat(bearingRad))
                UIView.animate(withDuration: 0.3, animations: { directionView.direction.transform = xfrm }) 
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate Implementation
extension SearchStopViewController: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        resetToolbar()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        switch (error as NSError).code {
        case CLError.Code.denied.rawValue:
            NSLog("Location services denied")
            locationManager.stopUpdatingLocation()
            break
        case CLError.Code.locationUnknown.rawValue:
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
    func process(stopPoints: StopPoints)
    {
        DispatchQueue.main.async {
            let annotations = self.map.annotations.flatMap { $0 as? BusStopAnnotation }
            let newStopPoints = stopPoints.stopPoints.filter { sp in
                !annotations.contains { sp == $0.stopPoint }
            }
            let defunctAnnotations = annotations.filter { !stopPoints.stopPoints.contains($0.stopPoint) }
            self.map.removeAnnotations(defunctAnnotations)
            self.map.addAnnotations(newStopPoints.map { BusStopAnnotation(stopPoint: $0) })
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func handle(error: NSError)
    {
        NSLog("\(error)")
        DispatchQueue.main.async {
            if self.presentedViewController == nil {
                let alertVC = UIAlertController(title: "Error Occurred", message: error.localizedDescription,
                    preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
}

// MARKY - NSFetchedResultsControllerDelegate Implementation
extension SearchStopViewController: NSFetchedResultsControllerDelegate
{
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    {
        DispatchQueue.main.async {
            let busStops = self.map.annotations.flatMap { $0 as? BusStopAnnotation }
            for stop in busStops {
                let view = self.map.view(for: stop)
                (view?.leftCalloutAccessoryView as! UIButton).setImage(FavouritesStar.get(.empty), for: UIControlState())
            }
            let favourites = controller.fetchedObjects as! [Favourite]
            for favourite in favourites {
                if let annotation = busStops.first( { $0.stopPoint.id == favourite.stationId } ),
                    let view = self.map.view(for: annotation) {
                    (view.leftCalloutAccessoryView as! UIButton).setImage(
                        FavouritesStar.get(.filled), for: UIControlState())
                }
            }
        }
    }
}

// MARK: - BusStopAnnocation Private Class
private class BusStopAnnotation: NSObject, MKAnnotation
{
    fileprivate (set) var stopPoint: StopPoint
    @objc var coordinate: CLLocationCoordinate2D {
        get {
            return stopPoint.location
        }
    }
    
    @objc fileprivate (set) var title: String?
    @objc fileprivate (set) var subtitle: String?
    
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

private class BusStopDetailButton: UIButton
{
    var annotation: MKAnnotation?
}

private func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool
{
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}
