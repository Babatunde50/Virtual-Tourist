//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Tunde Ola on 12/11/20.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var selectedPin: Pin?
    var pins = [Pin]()
    private var mapChangedFromUserInteraction = false
    
    
    @IBAction func longPressHandler(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
                let location = sender.location(in: mapView)
                let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
                
                let pin = Pin(context: dataController.viewContext)
                pin.latitude = coordinate.latitude
                pin.longitude = coordinate.longitude
                pin.creationDate = Date()
                pins.append(pin)
                try? dataController.viewContext.save()
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                mapView.addAnnotation(annotation)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        if let fetchResult = fetchRequestSetup() {
            pins = fetchResult
        }
        let lat = UserDefaults.standard.double(forKey: "Latitude")
        let lon = UserDefaults.standard.double(forKey: "Longitude")
        let location = CLLocation(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion( center: location.coordinate, latitudinalMeters: CLLocationDistance(exactly: 5000)!, longitudinalMeters: CLLocationDistance(exactly: 5000)!)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        var annotations = [MKPointAnnotation]()
        for object in pins {
            let annotation = MKPointAnnotation();
            annotation.coordinate = CLLocationCoordinate2D(latitude: object.latitude, longitude: object.longitude )
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
        
    }
    
    func fetchRequestSetup() -> [Pin]? {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return try? dataController.viewContext.fetch(fetchRequest)
    }
    
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        if let sender = sender {
            let location = sender.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.creationDate = Date()
            pins.append(pin)
            try? dataController.viewContext.save()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    
    //  MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageView" {
            let controller = segue.destination as! ImageViewController
            controller.pin = selectedPin
            controller.dataController = dataController
        }
    }
    

}



//  MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: "Latitude")
        UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: "Longitude")
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let pin = view.annotation!.coordinate
        if let foundPin = pins.first(where: { $0.latitude == pin.latitude && $0.longitude == pin.longitude } ) {
            selectedPin = foundPin
        }
        performSegue(withIdentifier: "imageView", sender: self)
    }
    
    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.ended  {
                    return true
                }
            }
        }
        return false
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
    }
}
