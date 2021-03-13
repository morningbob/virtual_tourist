//
//  PhotosCollectionViewController.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-24.
//

import UIKit
import MapKit
import CoreData

class PhotosCollectionViewController: UICollectionViewController{
  
  let apiKey = "c486a7ffc8d1a14c2dfa6543070e2b7a"

  var pictures = [Picture]()
  var dataController : DataController!
  var image: UIImage!
  var downloadList = [Int]()
  var picturesToSave = [Picture]()
  var picturesToDelete = [Picture]()
  var pin: Pin!
  var pictureIndexToSave = [Int]()
  var fetchedResultsControllerPictures: NSFetchedResultsController<Picture>!
  var photo_structs = [Photo]()
  var blockOperations: [BlockOperation] = []
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.collectionView.allowsMultipleSelection = true
    setupFetchedResultControllerPictures()
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
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return fetchedResultsControllerPictures.sections?[section].numberOfObjects ?? 0
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
    cell.photoImageView?.image = UIImage(named: "placeholder")
    let picture = fetchedResultsControllerPictures.object(at: indexPath) as Picture
    cell.photoImageView?.image = UIImage(data: picture.image!)
    
    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    // delete the photo
    let pictureToDelete = fetchedResultsControllerPictures.object(at: indexPath)
    dataController.viewContext.delete(pictureToDelete)
    try? dataController.viewContext.save()
   
    print("number of picutres now")
    print(fetchedResultsControllerPictures.sections?[0].numberOfObjects)
  }
  
  @IBAction func downloadAction(_ sender: UIBarButtonItem) {
    // start the download task
    // save the photos downloaded
    // display the new set of photos
   
    self.photo_structs = PhotosDownloader.downloadPhotos(pin: pin) { photos in
      self.createPictures(photos: photos)
      try? self.dataController.viewContext.save()
      self.setupFetchedResultControllerPictures()
      print("after fetch now")
      print(self.fetchedResultsControllerPictures.sections?[0].numberOfObjects)
    }
  
  }
  
  func createPictures(photos: [Photo]) {
    print("create pictures ran")
    print(photos.count)
    for photo in photos {
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
            picture.pin = self.pin
            self.pictures.append(picture)
            print("loading photo succeeded")
           
          }
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
 
}

extension PhotosCollectionViewController: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    if type == NSFetchedResultsChangeType.insert {
      print("Insert Object: \(String(describing: newIndexPath))")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.collectionView!.insertItems(at: [newIndexPath!])
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.update {
      print("Update Object: \(String(describing: indexPath))")
      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.collectionView!.reloadItems(at: [indexPath!])
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.move {
      print("Move Object: \(String(describing: indexPath))")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.delete {
      print("Delete Object: \(String(describing: indexPath))")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.collectionView!.deleteItems(at: [indexPath!])
          }
        })
      )
    }
  }

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    if type == NSFetchedResultsChangeType.insert {
      print("Insert Section: \(sectionIndex)")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.collectionView!.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.update {
      print("Update Section: \(sectionIndex)")
      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.collectionView!.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.delete {
      print("Delete Section: \(sectionIndex)")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.collectionView!.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
          }
        })
      )
    }
  }
}

/*

extension PhotosCollectionViewController: UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    if let pinVC = viewController as? PinListViewController {
      pinVC.dataController = self.dataController
    }
  }
}

extension PhotosCollectionViewController:NSFetchedResultsControllerDelegate {
    
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .insert:
        collectionView.insertItems(at: [newIndexPath!])
        break
    case .delete:
        collectionView.deleteItems(at: [indexPath!])
        break
    case .update:
        collectionView.reloadItems(at: [indexPath!])
    case .move:
        collectionView.moveItem(at: indexPath!, to: newIndexPath!)
    }
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    let indexSet = IndexSet(integer: sectionIndex)
    switch type {
    case .insert: collectionView.insertSections(indexSet)
    case .delete: collectionView.deleteSections(indexSet)
    case .update, .move:
        fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
    }
  }
  
  
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    //collectionView.reloadData()
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    collectionView.reloadData()
  }
  
}
 */

class PhotoCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var photoImageView: UIImageView!
  
  override var isSelected: Bool {
    didSet {
      if isSelected {
        photoImageView.backgroundColor = UIColor.blue
        
      } else {
        photoImageView.backgroundColor = UIColor.yellow
      }
    }
  }
  

}

/*
    loadImage(url: picture.url!) { error in
      if error != nil {
        print("error in loading")
      }
      DispatchQueue.main.async {
        cell.photoImageView?.image = self.image
      }
    }
 
 func loadImage(url: URL, completion: @escaping (Error?) -> Void) {
   
   let request = URLRequest(url: url)
   
   let task = URLSession.shared.dataTask(with: request) { data, response, error in
     if let error = error {
       completion(error)
       return
     }
     
     guard let data = data else {
       completion(error)
       return
     }
     
     self.image = UIImage(data: data)
     
     completion(nil)
   }
   task.resume()
 }
   */
