//
//  PinListViewController.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-28.
//

import UIKit
import MapKit
import CoreData

// display saved pins
class PinListViewController: UIViewController,
                             UITableViewDelegate, UITableViewDataSource,
                             NSFetchedResultsControllerDelegate {

  var dataController: DataController!
  var fetchedResultsController: NSFetchedResultsController<Pin>!
  var fetchedResultsControllerPictures: NSFetchedResultsController<Picture>!
  var pin: Pin!
  var pictures = [Picture]()
  
  
  @IBOutlet weak var tableView: UITableView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.delegate = self
    tableView.dataSource = self
    setupFetchedResultController()
    // setup inital pin for avoid crashing
    //pin = Pin(context: dataController.viewContext)
    //pin.id = UUID()
    //pin.latitude = -10.0
    //pin.longitude = -10.0
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    //fetchedResultsController = nil
    fetchedResultsControllerPictures = nil
  }
  
  fileprivate func setupFetchedResultController() {
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
  
  func setupFetchedResultControllerPictures() {
    let fetchRequest: NSFetchRequest<Picture> = Picture.fetchRequest()
    let predicate = NSPredicate(format: "pin == %@", pin)
    fetchRequest.predicate = predicate
    let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    fetchedResultsControllerPictures = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    
    fetchedResultsControllerPictures.delegate = self
    
    do {
      try fetchedResultsControllerPictures.performFetch()
    } catch {
      fatalError("The fetch could not be performed: \(error.localizedDescription)")
    }
   
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    fetchedResultsController = nil
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return fetchedResultsController.sections?.count ?? 1
  }
    
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let pin = fetchedResultsController.object(at: indexPath) as Pin

    let cell = tableView.dequeueReusableCell(withIdentifier: "PinCell", for: indexPath) as! PinCell
    cell.latitudeLabel.text = "Pin: " + String(pin.latitude)
    cell.longitudeLabel.text = String(pin.longitude)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    // retrieve photos associated with the pin
   
    self.pin = self.fetchedResultsController.object(at: indexPath) as Pin
    self.setupFetchedResultControllerPictures()
      
    self.getPicturesFromPin()
    if self.pictures.count != 0 {
      self.navigateToPhotoVC()
    } else {
      presentAlert(title: "Photos", message: "There is no associated photo for the pin.")
    }
      
  }
  
  func getPicturesFromPin() {
    if let pic = fetchedResultsControllerPictures.fetchedObjects {
      self.pictures = pic
    } else {
      print("The pin has no picture.")
    }
     
  }
  
  func navigateToPhotoVC() {
    let photoVC = self.storyboard!.instantiateViewController(withIdentifier: "PhotosCollectionViewController") as! PhotosCollectionViewController
    photoVC.dataController = self.dataController
    photoVC.pictures = self.pictures
    self.navigationController!.pushViewController(photoVC, animated: true)
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
}

class PinCell: UITableViewCell {
  
  @IBOutlet weak var latitudeLabel: UILabel!
  
  @IBOutlet weak var longitudeLabel: UILabel!
  
  override func prepareForReuse() {
    super.prepareForReuse()
    latitudeLabel.text = nil
    longitudeLabel.text = nil
    
  }
}
