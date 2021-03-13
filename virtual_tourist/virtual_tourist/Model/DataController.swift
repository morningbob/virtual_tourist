//
//  DataController.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-26.
//

import Foundation
import CoreData

class DataController {
  let persistentContainer: NSPersistentContainer
  
  var viewContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
  
  init(modelName: String) {
    persistentContainer = NSPersistentContainer(name: modelName)
  }
  
  func load(completion: (() -> Void)? = nil) {
    persistentContainer.loadPersistentStores { (storeDescription, error) in
      guard error == nil else {
        print("loading: error")
        fatalError(error!.localizedDescription)
      }
      completion?()
    }
  }
}
