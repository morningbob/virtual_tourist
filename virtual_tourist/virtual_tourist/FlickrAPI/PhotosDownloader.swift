//
//  PhotosDownloader.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-03-12.
//

import Foundation

class PhotosDownloader {
  
  class func downloadPhotos(pin: Pin, completion: @escaping ([Photo]) -> Void) -> [Photo] {
    var photo_structs = [Photo]()
    // make a request to get places
    FlickrAPIClient.findingPlace(apiKey: apiKey, lat: pin.latitude, lon: pin.longitude) { response, error in
      if response != nil {
        print("download success")
        photo_structs = (response?.photos.photo)!
        // create photo objects here
        print("photo structs")
        print(photo_structs.count)
        completion(photo_structs)
      } else {
        print("error happened")
        print(error?.localizedDescription)
      }
    }
    
    return photo_structs
  }
    /*
    func createPictures(pin: Pin) {
      
      for photo in photos_structs {
        let flickrPhoto = FlickrPhoto(farm: photo.farm, server: photo.server, id: photo.id, secret: photo.secret)

        flickrPhoto.loadImage() {
          error in
            if error != nil {
              print("error in loading photo")
            } else {
              let picture = Picture(context: self.dataController.viewContext)
              picture.id = UUID()
              picture.url = flickrPhoto.flickrImageURL()
              picture.image = flickrPhoto.image!.pngData()
              picture.pin = pin
              //self.pictures.append(picture)
            }
        }
      }
    }
 */
}
