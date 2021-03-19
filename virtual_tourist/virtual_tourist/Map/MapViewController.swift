//
//  MapViewController.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-21.
//

import UIKit
import MapKit
import CoreData
import Foundation

class MapViewController: UIViewController, UIGestureRecognizerDelegate,
                         NSFetchedResultsControllerDelegate,
                         MKMapViewDelegate {
  
  @IBOutlet weak var mapView: MKMapView!
  
  let apiKey = "c486a7ffc8d1a14c2dfa6543070e2b7a"
  
  var photos_structs = [Photo]()
  var photos = [Photo]()
  var pictures = [Picture]()
  var pinLocation = CLLocation()
  var dataController: DataController!
  var pinSelected: Pin!
  var fetchedResultsController: NSFetchedResultsController<Pin>!
  var pins = [Pin]()
  var annotations = [CustomAnnotation]()
  var latitude : String = ""
  var longitude : String = ""
  var latitudeDelta : String = "0.02"
  var longitudeDelta : String = "0.02"
  private var mapChangedFromUserInteraction = false
  var selectedAnnotation: CustomAnnotation?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // retrieve last pin in UserDefaults
    latitude = UserDefaults.standard.string(forKey: "latitude") ?? ""
    longitude = UserDefaults.standard.string(forKey: "longitude") ?? ""
    latitudeDelta = UserDefaults.standard.string(forKey: "latitudeDelta") ?? ""
    longitudeDelta = UserDefaults.standard.string(forKey: "longitudeDelta") ?? ""
    
    mapView.delegate = self
    
    // set zoom level and lat lon
    if let region = getMapRegion() {
      mapView.setRegion(region, animated: true)
    }
    
    setupFetchedResultController()
    addPinsAnnotation()
    
    // handle click and get coordinate
    let gestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                   action:#selector(self.mapLongTapped))
    gestureRecognizer.delegate = self
    gestureRecognizer.minimumPressDuration = 1.0
    mapView.addGestureRecognizer(gestureRecognizer)
  }
  
  func setupFetchedResultController() {
    let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    
    fetchedResultsController.delegate = self
    
    do {
      try fetchedResultsController.performFetch()
    } catch {
      fatalError("The fetch could not be performed: \(error.localizedDescription)")
    }
    
  }
  
  func addPinsAnnotation() {
    self.pins = fetchedResultsController.sections?[0].objects as [Pin]
    
    annotations = self.pins.map { pin in
      let annotation = CustomAnnotation()
      
      annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
      annotation.title = "past pin"
      annotation.pinId = pin.uuidString

      return annotation
    }
    
    self.mapView.addAnnotations(annotations)
  }
    
  @objc func mapLongTapped(gestureRecognizer: UILongPressGestureRecognizer) {
    // only triggered when it gesture ends
    if gestureRecognizer.state == UIGestureRecognizer.State.ended {
      // get the coordinate from the tapped map
      var location = gestureRecognizer.location(in: mapView)
      let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
    
      print("coordinate")
      print(coordinate)
      // get the lat long of the location
      pinLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    
      // populate the pinSelected
      self.pinSelected = Pin(context: dataController.viewContext)
      self.pinSelected.id = UUID()
      self.pinSelected.uuidString = self.pinSelected.id?.uuidString
      self.pinSelected.latitude = pinLocation.coordinate.latitude
      self.pinSelected.longitude = pinLocation.coordinate.longitude
     
      getPhotosFromLocation()
      
      // Add annotation:
      let annotation = CustomAnnotation()
      annotation.coordinate = coordinate
      annotation.pinId = self.pinSelected.uuidString
      mapView.addAnnotation(annotation)
      
      self.prepareAndNavigateToPhotoVC(selectedPinId: self.pinSelected.uuidString ?? "")
    }
    
    // save new pin and new associated photos
    //try? dataController.viewContext.save()
    // navigate to photoVC
    
  }
  
  func getPhotosFromLocation() {
    
    // make a request to get places
    FlickrAPIClient.findingPlace(apiKey: apiKey, lat: pinLocation.coordinate.latitude, lon: pinLocation.coordinate.longitude) { response, error in
      if response != nil {
        print("success")
        self.photos_structs = (response?.photos.photo)!
        // create photo objects here
        print("photo structs")
        print(self.photos_structs.count)
        // turn photo structs to picture objects
        self.createPictures()
        // save to database
        try? self.dataController.viewContext.save()
      } else {
        print("error happened")
        print(error?.localizedDescription)
      }
    }
  }
  
  func createPictures() {
    
    for photo in photos_structs {
      let flickrPhoto = FlickrPhoto(farm: photo.farm, server: photo.server, id: photo.id, secret: photo.secret)

      flickrPhoto.loadImage() {
        error in
          if error != nil {
            print("error in loading photo")
          } else {
            let picture = Picture(context: self.dataController.viewContext)
            //picture.id = UUID()
            picture.url = flickrPhoto.flickrImageURL()
            picture.image = flickrPhoto.image!.pngData()
            picture.pin = self.pinSelected
            self.pictures.append(picture)
          }
      }
    }
  }
  
  
  func saveRegion(mapRegion: MKCoordinateRegion?) {
    if let mapRegion = mapRegion {
      UserDefaults.standard.set(mapRegion.center.latitude, forKey: "latitude")
      UserDefaults.standard.set(mapRegion.center.longitude, forKey: "longitude")
      UserDefaults.standard.set(mapRegion.span.latitudeDelta, forKey: "latitudeDelta")
      UserDefaults.standard.set(mapRegion.span.longitudeDelta, forKey: "longitudeDelta")
    }
  }
  
  func getMapRegion() -> MKCoordinateRegion? {
    let location = CLLocation(latitude: Double(latitude)!, longitude: Double(longitude)!)
    let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees(latitudeDelta) ?? CLLocationDegrees(0.02), longitudeDelta: CLLocationDegrees(longitudeDelta) ?? CLLocationDegrees(0.02) ))
    return region
  }
  
  func prepareAndNavigateToPhotoVC(selectedPinId: String) {
    let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "uuidString = %@", selectedPinId)
    
    if let results = try? dataController.viewContext.fetch(fetchRequest) {
      if results.count <= 0 {
        // No object found
        print("can't find the pin")
        // show toast, no picture
      } else {
        self.pinSelected = results[0]
        print("got the pin")
        // navigate to PhotoVC
        let photoVC = self.storyboard!.instantiateViewController(identifier: "PhotosCollectionViewController") as! PhotosCollectionViewController
        
        photoVC.pictures = self.pictures
        photoVC.dataController = self.dataController
        photoVC.pin = self.pinSelected
        self.navigationController!.pushViewController(photoVC, animated: true)
      }
    }
  }
  
  func presentAlert(title: String, message: String) {
    let alert = UIAlertController(
         title: title,
         message: message,
         preferredStyle: .alert
     )
     alert.addAction(
         UIAlertAction(
             title: "OK",
             style: .default,
             handler: nil
         )
     )
     present(alert, animated: true, completion: nil)
  }
  
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      if (mapChangedFromUserInteraction) {
          print("New Region \(mapView.region)")
          saveRegion(mapRegion: mapView.region)
      }
  }
  
  
  func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
    print("region will change detected")
      mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
  }
  
  func mapViewRegionDidChangeFromUserInteraction() -> Bool {
    let view = self.mapView.subviews[0]
    print("region did changed detected ")
    //  Look through gesture recognizers to determine whether this region change is from user interaction
    if let gestureRecognizers = view.gestureRecognizers {
      for recognizer in gestureRecognizers {
        if ( recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.ended ) {
          print("returning true")
              return true
        }
      }
    }
    return false
  }
  
  // detect which pin is being clicked
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    print("did select")
    //guard case let self.selectedAnnotation = view.annotation as? CustomAnnotation else {
    //  return
    //}
    self.selectedAnnotation = view.annotation as? CustomAnnotation
    // check if the selected pin has any picture

    //let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    if let selectedPinId = self.selectedAnnotation?.pinId! {
    // retrieve the pin
      self.prepareAndNavigateToPhotoVC(selectedPinId: selectedPinId)
      //fetchRequest.predicate = NSPredicate(format: "uuidString = %@", selectedPinId)
    }
/*
    if let results = try? dataController.viewContext.fetch(fetchRequest) {
      if results.count <= 0 {
        // No object found
        print("can't find the pin")
        // show toast, no picture
      } else {
        self.pinSelected = results[0]
        print("got the pin")
        // navigate to PhotoVC
        let photoVC = self.storyboard!.instantiateViewController(identifier: "PhotosCollectionViewController") as! PhotosCollectionViewController
        
        photoVC.pictures = self.pictures
        photoVC.dataController = self.dataController
        photoVC.pin = self.pinSelected
        self.navigationController!.pushViewController(photoVC, animated: true)
      }
    }
 */
  }
 
    
}

class CustomAnnotation: MKPointAnnotation {
  var pinId: String!
}
/*

func getAddressFromCoordinates(pin: CLLocation) {
  let geoCoder = CLGeocoder()
  
  geoCoder.reverseGeocodeLocation(pin) { (placemarks, error) in
    // get the first placemark
    var placemark: CLPlacemark!
    placemark = placemarks?[0]
    // get location name from placemark
    if let locationName = placemark.name {
      print("name: \(locationName)")
    }
    
    if let street = placemark.thoroughfare {
      print("street: \(street)")
    }
    
    if let city = placemark.region {
      print("city: \(city)")
    }
    
    if let zip = placemark.postalCode {
      print("zip: \(zip)")
    }
    
    if let country = placemark.country {
      print("country: \(country)")
    }
  }
 }
 */

 
