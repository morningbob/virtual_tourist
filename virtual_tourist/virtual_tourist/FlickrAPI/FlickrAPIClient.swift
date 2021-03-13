//
//  FlickrAPIClient.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-22.
//

import Foundation

let apiKey = "c486a7ffc8d1a14c2dfa6543070e2b7a"

class FlickrAPIClient {
  
  
  enum Endpoints {
    static let base = "https://www.flickr.com/services/rest/?method=flickr.photos.search"
    
    case findPlace(String, Double, Double)
    
    var stringValue: String {
      switch self {
      case .findPlace(let apiKey, let lat, let lon): return Endpoints.base + "&api_key=\(apiKey)&lat=\(lat)&lon=\(lon)&accuracy=16&format=json"
      }
    }
    
    // accuracy 11 means city, format json response
    
    var url: URL {
      return URL(string: stringValue)!
    }
  }
  
  class func taskForFindingPlaceGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    //request.httpBody = try! JSONEncoder().encode(body)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data else {
        completion(nil, error)
        return
      }
  
      let decoder = JSONDecoder()
      let range = (14 ..< (data.count - 1))
      let newData = data.subdata(in: range)
      //print("Response data: \(String(data: newData, encoding: .utf8))")
      do {
        let responseObject = try decoder.decode(FindPlaceResponse.self, from: newData)
        completion(responseObject as! ResponseType, nil)
      } catch {
        do {
          print("data")
          print(String(data: newData, encoding: .utf8))
          let errorResponse = try decoder.decode(FindPlaceErrorResponse.self, from: newData) as Error
          completion(nil, errorResponse)
          print("successfully parsed the error")
          print(errorResponse)
        } catch {
          completion(nil, error)
          print("failed to parse the error")
          print(error)
        }
      }
    }
    task.resume()
  }
  
  class func taskForGettingPhotoGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    //request.httpBody = try! JSONEncoder().encode(body)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data else {
        completion(nil, error)
        return
      }
  
      
      let decoder = JSONDecoder()
      let range = (14 ..< (data.count - 1))
      let newData = data.subdata(in: range)
      //print("Response data: \(String(data: newData, encoding: .utf8))")
      do {
        let responseObject = try decoder.decode(FindPlaceResponse.self, from: newData)
        completion(responseObject as! ResponseType, nil)
      } catch {
        do {
          print("data")
          print(String(data: newData, encoding: .utf8))
          let errorResponse = try decoder.decode(FindPlaceErrorResponse.self, from: newData) as Error
          completion(nil, errorResponse)
          print("successfully parsed the error")
          print(errorResponse)
        } catch {
          completion(nil, error)
          print("failed to parse the error")
          print(error)
        }
      }
    }
    task.resume()
    
  }
  
  
  class func findingPlace(apiKey: String, lat: Double, lon: Double, completion: @escaping (FindPlaceResponse?, Error?) -> Void) {
    taskForFindingPlaceGETRequest(url: Endpoints.findPlace(apiKey, lat, lon).url, responseType: FindPlaceResponse.self) { response, error in
      if let response = response {
        completion(response, nil)
      } else {
        completion(nil, error)
      }
      
    }
  }
}
