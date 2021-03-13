//
//  FlickrPhoto.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-24.
//

import Foundation
import UIKit

class FlickrPhoto {
  
  let farm: Int
  let server: String
  let id: String
  let secret: String
  
  var image: UIImage?
  
  init (farm: Int, server: String, id: String, secret: String) {
    self.farm = farm
    self.server = server
    self.id = id
    self.secret = secret
  }
  
  func flickrImageURL(size: String = "m") -> URL? {
    if let url = URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(size).jpg") {
      return url
    }
    return nil
  }
  
  func loadImage(completion: @escaping (Error?) -> Void) {
    guard let loadURL = flickrImageURL() else {
      completion(nil)
      return
    }
    
    let request = URLRequest(url: loadURL)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        print("there is error")
        completion(error)
      
        return
      }
      
      guard let data = data else {
        print("data has error")
        completion(error)
        return
      }
      
      let image = UIImage(data: data)
      self.image = image
      //print("there is no error")
      completion(nil)
    }
    task.resume()
  }
}
