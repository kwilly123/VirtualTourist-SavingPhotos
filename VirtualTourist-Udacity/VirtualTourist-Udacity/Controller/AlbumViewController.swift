//
//  AlbumViewController.swift
//  VirtualTourist-Udacity
//
//  Created by Kyle Wilson on 2020-03-17.
//  Copyright © 2020 Xcode Tips. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    
    var pinSelected: Pin!
    
    var locationRetrieved: CLLocationCoordinate2D?
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    var photoImages = [UIImage]()
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var image: UIImage?
    
    //MARK: viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pin()
        setupFetchedResultsController()
        downloadPhotos()
        mapView.isUserInteractionEnabled = false
    }
    
    //MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.collectionViewLayout = flowLayout
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        print("LAT: \(pinSelected.latitude)")
        print("LONG: \(pinSelected.longitude)")
        
        collectionView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
    }
    
    //MARK: viewWillDisappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK: NEW COLLECTION
    
    @IBAction func newCollectionTapped(_ sender: Any) {
        photoImages.removeAll()
        collectionView.reloadData()
        downloadPhotos()
    }
    
    //MARK: GEOCODE LOCATION
    
    func pin() {
        
        let coordinate = CLLocationCoordinate2D(latitude: pinSelected.latitude, longitude: pinSelected.longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(region, animated: true)
            self.mapView.regionThatFits(region)
        }
    }
    
    //MARK: DOWNLOAD PHOTOS
    
    func downloadPhotos() {
        FlickrClient.searchPhotos(latitude: self.pinSelected!.latitude, longitude: self.pinSelected!.longitude, totalPages: 3) { (result, error) in
            
            DispatchQueue.main.async {
                self.photoImages = result
                self.savePhotosToLocalStorage(photosArray: self.photoImages)
                self.collectionView.reloadData()
            }
        }
    }
    
    //MARK: SAVE PHOTOS
    
    func savePhotosToLocalStorage(photosArray:[UIImage]){
        for photo in photosArray{
            addPhotosForPin(photo: photo)
        }
    }
    
    func addPhotosForPin(photo: UIImage){
        let photos = Photo(context: dataController.viewContext)
        let imageData : Data = photo.pngData()!
        photos.photo = imageData
        photos.pin = pinSelected
        try? dataController.viewContext.save()
    }
    
    //MARK: SETUP FETCHED
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pinSelected)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "photo", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(String(describing: pinSelected))-photos")
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch Error: \(error.localizedDescription)")
        }
        
    }
    
}

//MARK: DELEGATES

extension AlbumViewController: DeleteCell {
    
    func delete(index: IndexPath) {
        photoImages.remove(at: index.row)
        collectionView.reloadData()
        let photoToDelete = fetchedResultsController.object(at: index)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
    
}

extension AlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //MARK: COLLECTION CELL
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionCell  = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCell
        if (photoImages.count > 0){
            DispatchQueue.main.async {
                collectionCell?.cellWithImage(imageFetched: self.photoImages[indexPath.row])
                collectionCell?.index = indexPath
                collectionCell?.delegate = self
            }
        } else {
            DispatchQueue.main.async {
                collectionCell?.cellWithPlaceHolder()
            }
        }
        return collectionCell!
    }
    
    //MARK: NUMBER OF CELLS
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(photoImages.count == 0){
            return 21
        } else {
            return photoImages.count
        }
    }
    
    //MARK: CELL SIZE
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    
}

extension AlbumViewController: MKMapViewDelegate {
    
    //MARK: MAKE PIN
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView?.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}


