//
//  ImageViewController.swift
//  Virtual Tourist
//
//  Created by Tunde Ola on 12/11/20.
//

import UIKit
import MapKit
import CoreData
import Kingfisher

class ImageViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    var pin: Pin!
    var dataController: DataController!
    var photos = [Photo]()
    var page = 1
    let insets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    let itemsPerRow: CGFloat = 5
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        setNewCollectionButton(to: false)
        
        if let fetchResult = fetchRequestSetup() {
            if fetchResult.count == 0 {
                getImages(page)
            } else {
                photos = fetchResult
                setNewCollectionButton(to: true)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let location = CLLocation(latitude: pin!.latitude, longitude: pin!.longitude)
        let region = MKCoordinateRegion( center: location.coordinate, latitudinalMeters: CLLocationDistance(exactly: 5000)!, longitudinalMeters: CLLocationDistance(exactly: 5000)!)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
        let annotation = MKPointAnnotation();
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin!.latitude, longitude: pin!.longitude )
        mapView.addAnnotation(annotation)
    }
    
    func fetchRequestSetup() -> [Photo]? {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return try? dataController.viewContext.fetch(fetchRequest)
    }
    
    @IBAction func newCollectionHandler(_ sender: UIBarButtonItem) {
        if let photos = fetchRequestSetup() {
            for photo in photos {
                dataController.viewContext.delete(photo)
                try? dataController.viewContext.save()
            }
        }
        page += 1
        getImages(page)
    }
    
    func setNewCollectionButton(to state: Bool) {
        newCollectionButton.isEnabled = state
    }
    
    func getImages(_ page: Int) {
        setNewCollectionButton(to: false)
        FlickrClient.getGeoPhotos(lat: pin.latitude, lon: pin.longitude, page: page) { (data, error) in
            if error != nil {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "An error occured", message: error?.localizedDescription , preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            guard let data = data else { return }
            if data.count == 0 {
                DispatchQueue.main.async {
                    self.collectionView.setEmptyMessage()
                }
                return
            } else {
                DispatchQueue.main.async {
                    self.collectionView.deleteEmptyMessage()
                }
            }
            for imageData in data {
                if let url = imageData.urlSq {
                    let imageURL = URL(string: url)
                    let photo: Photo = Photo(context: self.dataController.viewContext)
                    photo.url = imageURL!
                    photo.creationDate = Date()
                    photo.pin = self.pin
                    try? self.dataController.viewContext.save()
                }
            }
            
            if let result = self.fetchRequestSetup() {
                self.photos = result
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.setNewCollectionButton(to: true)
                }
            }
        }
    }

}

extension ImageViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = photos[indexPath.row]
        photos.remove(at: indexPath.row)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        collectionView.reloadData()
    }
}

//  MARK: - UICollectionViewDataSource
extension ImageViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionView", for: indexPath) as! ImageCollectionViewCell

        let singlePhoto = photos[indexPath.row]
        if let photoData = singlePhoto.image {
            cell.imageView.image = UIImage(data: photoData)
        } else if let photoURL = singlePhoto.url {
            // download image
            let image = UIImage(named: "placeholder")
            cell.imageView.kf.setImage(with: photoURL, placeholder: image, options: [.transition(.fade(0.2))], completionHandler:  { (result) in
                switch result {
                    case .success(let value):
                        singlePhoto.image = value.image.pngData()
                        try? self.dataController.viewContext.save()

                    case .failure(let error):
                        DispatchQueue.main.async {
                            let alertController = UIAlertController(title: "An error occured", message: error.localizedDescription , preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
            })
        }
        cell.layoutIfNeeded()
        return cell
    }
    
}

//  MARK: - UICollectionViewDelegateFlowLayout
extension ImageViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = insets.right * (itemsPerRow + 2)
        let availableWidth = view.frame.width + padding
        let widthOfItem = availableWidth / itemsPerRow
        print(widthOfItem, "WIDTH OF ITEM")
        return CGSize(width: widthOfItem, height: widthOfItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return insets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return insets.right
    }
}

//  MARK: - UICollectionView
extension UICollectionView {
    func setEmptyMessage() {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = "No Images"
        messageLabel.textAlignment = .center;
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
    }
    
    func deleteEmptyMessage() {
        self.backgroundView = nil
    }
}
