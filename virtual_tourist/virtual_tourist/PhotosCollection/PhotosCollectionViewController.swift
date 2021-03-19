//
//  PhotosCollectionViewController.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-24.
//

import UIKit
import MapKit
import CoreData

class PhotosCollectionViewController: UICollectionViewController,
                                      UICollectionViewDelegateFlowLayout
                                      {
  
  let apiKey = "c486a7ffc8d1a14c2dfa6543070e2b7a"

  var pictures = [Picture]()
  var dataController : DataController!
  var image: UIImage!
  var pin: Pin!
  var fetchedResultsControllerPictures: NSFetchedResultsController<Picture>!
  var photo_structs = [Photo]()
  var blockOperations: [BlockOperation] = []
  var date = Date()
  var picture : Picture!
  
  @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //self.collectionView.allowsMultipleSelection = true
    setupFetchedResultControllerPictures()
   
    
    let space:CGFloat = 3.0
    let dimension = (view.frame.size.width - (2 * space)) / 3.0
    
    flowLayout.minimumInteritemSpacing = space
    flowLayout.minimumLineSpacing = space
    flowLayout.itemSize = CGSize(width: dimension, height: dimension)
  }
  
  func setupFetchedResultControllerPictures() {
    let fetchRequest: NSFetchRequest<Picture> = Picture.fetchRequest()
    let predicate = NSPredicate(format: "pin == %@", pin)
    fetchRequest.predicate = predicate
    let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    fetchedResultsControllerPictures = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    
    fetchedResultsControllerPictures.delegate = self
    
    do {
      try fetchedResultsControllerPictures.performFetch()
    } catch {
      fatalError("The fetch could not be performed: \(error.localizedDescription)")
    }
   
  }
  
  func fetchNewCollection() {
    let fetchRequest: NSFetchRequest<Picture> = Picture.fetchRequest()
    let pinPredicate = NSPredicate(format: "pin == %@", pin)
    let datePredicate = NSPredicate(format: "date >= %@", date as NSDate)
    let subpredicates: [NSPredicate]
    subpredicates = [pinPredicate, datePredicate]
    let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
    fetchRequest.predicate = compoundPredicate
    let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
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
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.frame.size.width/3, height: collectionView.frame.size.width/3)
    }
  
  
  @IBAction func downloadAction(_ sender: UIBarButtonItem) {
    // start the download task
    // save the photos downloaded
    // display the new set of photos
   
    self.photo_structs = PhotosDownloader.downloadPhotos(pin: pin) { photos in
      self.createPictures(photos: photos)

    }
  
  }
  // completion: @escaping (ResponseType?, Error?) -> Void
  func createPictures(photos: [Photo] ) {
    print("create pictures ran")
    print(photos.count)
    if photos.count == 0 {
      self.presentAlert(title: "Photos", message: "No photo available.")
      return
    }
    let group = DispatchGroup()
    group.enter()
    // get the date and time for the first picture in the new collection
    // to use in fetching new colleciton
    date = Date()
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
            picture.date = Date()
          
          }
      }
    }
    print("finished creating photos")
    group.leave()
    group.wait()

    try? self.dataController.viewContext.save()
    self.fetchNewCollection()
    print("after fetch now")
    print(self.fetchedResultsControllerPictures.sections?[0].numberOfObjects)
    DispatchQueue.main.async {
      self.presentAlert(title: "Download Photos", message: "Downloaded 250 new photos.")
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
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
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
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
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
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
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
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
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
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
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
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
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
      DispatchQueue.main.async {
        self.collectionView.reloadData()
      }
    }
  }
}


class PhotoCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var photoImageView: UIImageView!
  /*
  override var isSelected: Bool {
    didSet {
      if isSelected {
        photoImageView.backgroundColor = UIColor.blue
        
      } else {
        photoImageView.backgroundColor = UIColor.yellow
      }
    }
  }
  */

}

