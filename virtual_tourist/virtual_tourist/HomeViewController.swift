//
//  ViewController.swift
//  virtual_tourist
//
//  Created by Jessie Hon on 2021-02-21.
//

import UIKit

class HomeViewController: UIViewController {
  
  var dataController : DataController!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
 
  }

  @IBAction func actionStart(_ sender: UIButton) {
   
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //let mapVC = storyboard?.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
    
    if segue.identifier == "toMapVC" {
      let mapVC = segue.destination as! MapViewController
      mapVC.dataController = self.dataController
    }
    
  }
  
  
  
  
    
  
}

