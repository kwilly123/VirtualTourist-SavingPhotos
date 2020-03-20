//
//  MapViewController.swift
//  VirtualTourist-Udacity
//
//  Created by Kyle Wilson on 2020-03-17.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    var dataController: DataController!
    
    
    //MARK: viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    //MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        view.addGestureRecognizer(longTapGesture)
        
        setupFetchedResultsController()
        drawPinsOnMap()
    }
    
    //MARK: viewWillDisappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    //MARK: LONG TAP GESTURE
    
    @objc func longTap(sender: UIGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: self.mapView)
            let locationOnMap = self.mapView.convert(location, toCoordinateFrom: self.mapView) //location of where user long pressed
            
            let latitude = locationOnMap.latitude
            let longitude = locationOnMap.longitude
            
            let pin = Pin(context: dataController.viewContext) //create pin
            pin.latitude = latitude //add attributes to pin
            pin.longitude = longitude
            try? dataController.viewContext.save() //and save pin
            
//            let latitude = CLLocationDegrees(latitude)
//            let longitude = CLLocationDegrees(longitude)
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude , longitude: longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            self.mapView.addAnnotation(annotation)
        }
    }
    
    //MARK: DRAW PINS
    
    func drawPinsOnMap(){
        
        var savedPins : [MKAnnotation] = []
        for pin in fetchedResultsController.fetchedObjects!{
            
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            savedPins.append(annotation)
            
        }
        mapView.addAnnotations(savedPins)
    }
    
    //MARK: PREPARE
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is AlbumViewController {
            let vc = segue.destination as? AlbumViewController
            vc?.dataController = dataController
            vc?.pinSelected = sender as? Pin
        }
    }
    
    //MARK: SETUP FETCHED
    
    func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch Error: \(error.localizedDescription)")
        }
    }
    
}

//MARK: DELEGATES

extension MapViewController: MKMapViewDelegate {
    
    //MARK: MAKE PIN
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    //MARK: TAPPED ANNOTATION VIEW
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = (view.annotation?.coordinate.latitude)!
        pin.longitude = (view.annotation?.coordinate.longitude)!
        
        performSegue(withIdentifier: "segue", sender: pin)
    }
}
