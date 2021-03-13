//
//  PhotosListViewController.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-24.
//

import UIKit

class PhotosListViewController: UIViewController, UITableViewDelegate,
                                UITableViewDataSource {

  @IBOutlet weak var tableView: UITableView!
  
  
  var photos_structs = [Photo]()
  var photos = [FlickrPhoto]()
  

  override func viewDidLoad() {
    super.viewDidLoad()

    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    getPhotos()
    
  }
    
  // turn the structs into phots
  func getPhotos() {
    if photos_structs.count != 0 {
      photos = photos_structs.map { photo in
        return FlickrPhoto(farm: photo.farm, server: photo.server, id: photo.id,
                           secret: photo.secret)
      }
    }
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 25
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell")! 
    return cell
  }
   
}
