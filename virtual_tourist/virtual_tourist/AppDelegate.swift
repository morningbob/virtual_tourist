//
//  AppDelegate.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    
    checkIfFirstLaunch()
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
  
  func checkIfFirstLaunch() {
    if UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
      print("App has launched before")
    } else {
      UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
      UserDefaults.standard.set(String(40.730610), forKey: "latitude")
      UserDefaults.standard.set(String(-73.935242), forKey: "longitude")
      UserDefaults.standard.set("0.02", forKey: "latitudeDelta")
      UserDefaults.standard.set("0.02", forKey: "longitudeDelta")
      
      UserDefaults.standard.synchronize()
    }
  }


}

