//
//  ViewController.swift
//  HealthTutorial
//
//  Created by HanKyusun on 2016. 9. 6..
//  Copyright © 2016년 sum company. All rights reserved.
//

import UIKit
import HealthKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var lastLocationLbl: UILabel!
    @IBOutlet weak var currentLocationLbl: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var milesLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    let locationManager = CLLocationManager()
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var distanceTraveled = 0.0
    var timer: NSTimer!
    var zeroTime = NSTimeInterval()
    
    let healthManager:HealthKitManager = HealthKitManager()
    var height, weight:HKQuantitySample?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        } else {
            print("Need to Enable Location")
        }
        
        // We cannot access the user's HealthKit data without specific permission.
        getHealthKitPermission()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func share(sender: AnyObject) {
        healthManager.saveDistance(distanceTraveled, date: NSDate())
    }
    @IBAction func startAction(sender: AnyObject) {
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: Selector("updateTime"), userInfo: nil, repeats: true)
        zeroTime = NSDate.timeIntervalSinceReferenceDate()
        
        distanceTraveled = 0.0
        startLocation = nil
        lastLocation = nil
        
        locationManager.startUpdatingLocation()
    }
    
    
    @IBAction func stopTimer(sender: AnyObject) {
        timer.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    func updateTime() {
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        var timePassed: NSTimeInterval = currentTime - zeroTime
        let minutes = UInt8(timePassed / 60.0)
        timePassed -= (NSTimeInterval(minutes) * 60)
        let seconds = UInt8(timePassed)
        timePassed -= NSTimeInterval(seconds)
        
        let millisecsX10 = UInt8(timePassed * 100)
        
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        let strMSX10 = String(format: "%02d", millisecsX10)
        
        timerLabel.text = "\(strMinutes):\(strSeconds):\(strMSX10)"

        if timerLabel.text == "60:00:00" {
            timer.invalidate()
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if startLocation == nil {
            startLocation = locations.first as CLLocation!
            lastLocationLbl.text = "\(startLocation.coordinate)"
            print(startLocation)
        } else {
            let lastDistance = lastLocation.distanceFromLocation(locations.last as CLLocation!)
            distanceTraveled += lastDistance
            
            let trimmedDistance = String(format: "%.2f", distanceTraveled)
            
            milesLabel.text = "\(trimmedDistance) Meters"
        }

        lastLocation = locations.last as CLLocation!
        
        currentLocationLbl.text = "\(lastLocation.coordinate)"
        print("start")
    }


    func getHealthKitPermission() {
        
        // Seek authorization in HealthKitManager.swift.
        healthManager.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                // Get and set the user's height.
                self.setHeight()
                self.setWeight()
            } else {
                if error != nil {
                    print(error)
                }
                print("Permission denied.")
            }
        }
    }
    
    func setHeight(){
        //신장 값을 위한 HK샘플러 만들기
        let heightSample = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
        
        //유저의 신장를 알기 위해 헬스매니저의 getSample 함수를 부른다.
        self.healthManager.getHeight(heightSample!, completion: {(userHeight, error) -> Void in
            if (error != nil){
                print("Error: \(error.localizedDescription)")
            }
            var heightString = ""
            self.height = userHeight as? HKQuantitySample
            
            //신장 값을 유저의 장소에 따라 포맷
            if let meters = self.height?.quantity.doubleValueForUnit(HKUnit.meterUnit()) {
                let formatHeight = NSLengthFormatter()
                formatHeight.forPersonHeightUse = true
                heightString = formatHeight.stringFromMeters(meters)
            }
            //유저의 신장 값을 반영하기 위해 라벨을 세팅
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.heightLabel.text = heightString
            })
        })
    }
    
    func setWeight(){
        print("setWeight")
        let weightSample = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
        self.healthManager.readMostRecentSample(weightSample!, completion: {(mostRecentWeight, error) -> Void in
            if (error != nil){
                print("Error: \(error.localizedDescription)")
            }
            print("setWeight2")

            var weightLocalizedString = ""
            // 3. Format the weight to display it on the screen
            self.weight = mostRecentWeight as? HKQuantitySample;
            if let kilograms = self.weight?.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo)) {
                let weightFormatter = NSMassFormatter()
                weightFormatter.forPersonMassUse = true;
                weightLocalizedString = weightFormatter.stringFromKilograms(kilograms)
                print("setWeight3")
            }
            
            // 4. Update UI in the main thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.weightLabel.text = weightLocalizedString
               // self.updateBMI()
            });
            
        })
    }
}

