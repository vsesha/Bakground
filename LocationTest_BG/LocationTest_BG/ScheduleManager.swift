//
//  ScheduleManager.swift
//  LocationTest_BG
//
//  Created by Vasudevan Seshadri on 9/20/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

public protocol APScheduledLocationManagerDelegate {
    
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didFailWithError error: Error)
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didUpdateLocations locations: [CLLocation])
    func scheduledLocationManager(_ manager: APScheduledLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
}


public class APScheduledLocationManager: NSObject, CLLocationManagerDelegate {
    
    private let MaxBGTime: TimeInterval = 170
    private let MinBGTime: TimeInterval = 2
    private let MinAcceptableLocationAccuracy: CLLocationAccuracy = 5
    private let WaitForLocationsTime: TimeInterval = 3
    
    private let delegate: APScheduledLocationManagerDelegate
    private let manager = CLLocationManager()
    
    private var isManagerRunning = false
    private var checkLocationTimer: Timer?
    private var waitTimer: Timer?
    private var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    private var lastLocations = [CLLocation]()
    
    public private(set) var acceptableLocationAccuracy: CLLocationAccuracy = 100
    public private(set) var checkLocationInterval: TimeInterval = 10
    public private(set) var isRunning = false
    
    public init(delegate: APScheduledLocationManagerDelegate) {
        
        self.delegate = delegate
        
        super.init()
        
        configureLocationManager()
    }
    
    private func configureLocationManager(){
        NSLog("configureLocationManager")
        
        manager.allowsBackgroundLocationUpdates = true
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        manager.delegate = self
    }
    
    public func requestAlwaysAuthorization() {
        
        manager.requestAlwaysAuthorization()
    }
    
    public func startUpdatingLocation(interval: TimeInterval, acceptableLocationAccuracy: CLLocationAccuracy = 100) {
        
        NSLog("Inside startUpdatingLocation - isRunning = \(isRunning)")
        
        if isRunning {
            NSLog("Inside startUpdatingLocation - stopUpdatingLocation")
            stopUpdatingLocation()
        }
        
        checkLocationInterval = interval > MaxBGTime ? MaxBGTime : interval
        checkLocationInterval = interval < MinBGTime ? MinBGTime : interval
        
        NSLog("Inside startUpdatingLocation - setting accuracy")
        self.acceptableLocationAccuracy = acceptableLocationAccuracy < MinAcceptableLocationAccuracy ? MinAcceptableLocationAccuracy : acceptableLocationAccuracy
        
        isRunning = true
        NSLog("Inside startUpdatingLocation - will addNotifications")
        addNotifications()
        NSLog("Inside startUpdatingLocation - will startLocationManager")
        startLocationManager()
    }
    
    public func stopUpdatingLocation() {
        NSLog("Inside stopUpdatingLocation - will stop all")
        isRunning = false
        
        stopWaitTimer()
        stopLocationManager()
        stopBackgroundTask()
        stopCheckLocationTimer()
        removeNotifications()
    }
    
    private func addNotifications() {
        NSLog("Inside addNotifications")
        removeNotifications()
        
        NotificationCenter.default.addObserver(self, selector:  #selector(applicationDidEnterBackground),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector:  #selector(applicationDidBecomeActive),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive,
                                               object: nil)
        NSLog("Exiting addNotifications")
    }
    
    private func removeNotifications() {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    private func startLocationManager() {
        NSLog(" Inside startLocationManager")
        isManagerRunning = true
        manager.startUpdatingLocation()
    }
    
    private func stopLocationManager() {
        NSLog(" Inside StopLocationManager")
        isManagerRunning = false
        manager.stopUpdatingLocation()
    }
    
    @objc func applicationDidEnterBackground() {
        NSLog(" Inside applicationDidEnterBackground")
        
        NSLog(" Inside applicationDidEnterBackground - stopBackgroundTask")
        stopBackgroundTask()
        
        NSLog(" Inside applicationDidEnterBackground - stopBackgroundTask")
        startBackgroundTask()
    }
    
    @objc func applicationDidBecomeActive() {
        NSLog(" Inside applicationDidBecomeActive - will stopBackgroundTask")
        stopBackgroundTask()
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        NSLog(" Inside locationManager :: didChangeAuthorizationk")
        delegate.scheduledLocationManager(self, didChangeAuthorization: status)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog(" Inside locationManager :: didFailWithError")
        delegate.scheduledLocationManager(self, didFailWithError: error)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog(" Inside locationManager :: didUpdateLocations - isRunning = \(isRunning)")
        
        guard isManagerRunning else { return }
        
        NSLog(" Inside locationManager :: didUpdateLocations - locations.count = \(locations.count)")
        guard locations.count>0 else { return }
        
        lastLocations = locations
        
        NSLog(" Inside locationManager :: didUpdateLocations - waitTimer = \(waitTimer)")
        
        if waitTimer == nil {
            NSLog(" Inside locationManager :: didUpdateLocations will startWaitTimer()")
            startWaitTimer()
        }
    }
    
    private func startCheckLocationTimer() {
        NSLog(" Inside startCheckLocationTimer about to  stopCheckLocationTimer()")
        stopCheckLocationTimer()
        
        NSLog(" Inside setting  checkLocationTimer to  \(checkLocationInterval) Secs")
        
        checkLocationTimer = Timer.scheduledTimer(timeInterval: checkLocationInterval, target: self, selector: #selector(checkLocationTimerEvent), userInfo: nil, repeats: false)
    }
    
    private func stopCheckLocationTimer() {
         NSLog(" Inside   stopCheckLocationTimer ")
        
        if let timer = checkLocationTimer {
            NSLog(" timer  =  checkLocationTimer ")
            NSLog(" timer  will be invalidate ")
            timer.invalidate()
            checkLocationTimer=nil
        }
    }
    
    func checkLocationTimerEvent() {
        NSLog(" inside checkLocationTimerEvent, will stopCheckLocationTimer ")
        stopCheckLocationTimer()
        
        NSLog(" inside checkLocationTimerEvent, will startLocationManager - isManagerRunning = \(isManagerRunning) ")
        startLocationManager()
        
        NSLog(" inside checkLocationTimerEvent, will stopAndResetBgTaskIfNeeded ")
        // starting from iOS 7 and above stop background task with delay, otherwise location service won't start
        self.perform(#selector(stopAndResetBgTaskIfNeeded), with: nil, afterDelay: 1)
    }
    
    private func startWaitTimer() {
        NSLog(" inside startWaitTimer - about to StopWaitTimer ")
        stopWaitTimer()
        
        NSLog(" inside startWaitTimer - waitTimer set to \(WaitForLocationsTime) Secs ")
        waitTimer = Timer.scheduledTimer(timeInterval: WaitForLocationsTime, target: self, selector: #selector(waitTimerEvent), userInfo: nil, repeats: false)
    }
    
    private func stopWaitTimer() {
         NSLog(" inside stopWaitTimer ")
        if let timer = waitTimer {
            NSLog(" timer =  waitTimer hence invalidating ")
            timer.invalidate()
            waitTimer=nil
        }
    }
    
    func waitTimerEvent() {
        NSLog(" Inside  waitTimerEvent will stopWaitTimer()")
        stopWaitTimer()
        
        if acceptableLocationAccuracyRetrieved() {
            NSLog(" Inside  waitTimerEvent - will startBackgroundTask")
            
            startBackgroundTask()
            
            NSLog(" Inside  waitTimerEvent - Will startCheckLocationTimer")
            startCheckLocationTimer()
            
            NSLog(" Inside  waitTimerEvent -  Will stopLocationManager")
            stopLocationManager()
            
            NSLog(" Inside  waitTimerEvent Will - delegate.scheduledLocationManager")
            delegate.scheduledLocationManager(self, didUpdateLocations: lastLocations)
        }else{
            NSLog(" Inside  Accuracy is not true - will StartWaitTimer()")
            
            startWaitTimer()
        }
    }
    
    private func acceptableLocationAccuracyRetrieved() -> Bool {
        NSLog(" Inside  acceptableLocationAccuracyRetrieved()")
        let location = lastLocations.last!
        NSLog(" location.horizontalAccuracy = \(location.horizontalAccuracy) and acceptableLocationAccuracy =\(acceptableLocationAccuracy)")
        return location.horizontalAccuracy <= acceptableLocationAccuracy ? true : false
    }
    
    func stopAndResetBgTaskIfNeeded()  {
        NSLog(" Inside  stopAndResetBgTaskIfNeeded - isManagerRunning = \(isManagerRunning)")
        if isManagerRunning {
            NSLog(" Inside  stopAndResetBgTaskIfNeeded will only stopBackgroundTask")

            stopBackgroundTask()
        }else{
            NSLog(" Inside  stopAndResetBgTaskIfNeeded will do both stop and start BackgroundTask")
            stopBackgroundTask()
            startBackgroundTask()
        }
    }
    
    private func startBackgroundTask() {
        
        NSLog(" Inside  startBackgroundTask")
        
        let state = UIApplication.shared.applicationState
        
        NSLog(" Inside  startBackgroundTask checking state")
        if ((state == .background || state == .inactive) && bgTask == UIBackgroundTaskInvalid) {
            NSLog(" Inside  startBackgroundTask - about to begin BG")
            
            bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                NSLog(" Inside  startBackgroundTask - about to checkLocationTimerEvent")
                self.checkLocationTimerEvent()
            })
        }
    }
    
    @objc private func stopBackgroundTask() {
         NSLog(" Inside  stopBackgroundTask")
        guard bgTask != UIBackgroundTaskInvalid else { return }
        NSLog(" Inside  stopBackgroundTask - will endBackgroundTask ")
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
    }
}
