//
//  ViewController.swift
//  LocationTest_BG
//
//  Created by Vasudevan Seshadri on 9/20/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit
//import ScheduledLocationManager
import CoreLocation
import AudioToolbox

class ViewController: UIViewController, APScheduledLocationManagerDelegate {
    
    private var manager: APScheduledLocationManager!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = APScheduledLocationManager(delegate: self)
    }
    
    @IBAction func startStop(_ sender: AnyObject) {
    NSLog("1")
        if manager.isRunning {
            NSLog("2")
            startStopButton.setTitle("start", for: .normal)
            NSLog("3")
            manager.stopUpdatingLocation()
            NSLog("4")
        }else{
            NSLog("5")
            
            if CLLocationManager.authorizationStatus() == .authorizedAlways {
                NSLog("6")
                
                startStopButton.setTitle("stop", for: .normal)
                NSLog("7")
                manager.startUpdatingLocation(interval: 15, acceptableLocationAccuracy: 10000)
                NSLog("8")
            }else{
                NSLog("9")
                manager.requestAlwaysAuthorization()
            }
            NSLog("10")
        }
        NSLog("11")
    }
    
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("ViewController :: didUpdateLocations")
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        
        let l = locations.first!
        
        textView.text = "\(textView.text!)\r \(formatter.string(from: Date())) loc: \(l.coordinate.latitude), \(l.coordinate.longitude)"
        AudioServicesPlayAlertSound(SystemSoundID(1012))
        
    }
    
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didFailWithError error: Error) {
        
    }
    
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
}

