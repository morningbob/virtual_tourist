//
//  FindPlaceResponse.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-22.
//

import Foundation

struct FindPlaceResponse : Codable {
  let photos: PhotoCollection
}

struct PhotoCollection : Codable {
  let photo: [Photo]
}

struct Photo : Codable {
  let id: String
  let farm: Int
  let server: String
  let secret: String
}

/*
struct FindPlaceResponse : Codable {
  let places: Place
  let status: String
  
  enum CodingKeys: String, CodingKey {
    case places
    case status = "stat"
  }
}

struct Place : Codable {
  let place: [String]
  let latitude: String
  let longitude: String
  let accuracy: String
  let total: Int
  
}
*/

