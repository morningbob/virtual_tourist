//
//  FindPlaceErrorResponse.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-23.
//

import Foundation

struct FindPlaceErrorResponse : Codable {
  let status : String
  let code : Int
  let message : String
  
  enum CodingKeys: String, CodingKey {
    case status = "stat"
    case code
    case message
  }
}

// add the extension so that it conforms to Swift's Error

extension FindPlaceErrorResponse: LocalizedError {
  var errorDescription: String? {
    return message
  }
}
