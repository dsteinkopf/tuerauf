//
//  ViewController.swift
//  tuerauf
//
//  Created by Dirk Steinkopf on 04.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var jetztOeffnenButton: UIButton!
    @IBOutlet var ergebnisLabel: UILabel!
    @IBOutlet var pinEntryField: UITextField!
    @IBOutlet var bgImage: UIImageView!
    @IBOutlet var pinResultLabel: UILabel!
    @IBOutlet var versionLabel: UILabel!

    let locationManager = CLLocationManager()
    let NEEDED_ACCURACY_IN_M = 75.0
    var geoy: Double = 0.0
    var geox: Double = 0.0
    var gotGeolocation = false


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ergebnisLabel.text = ""
        pinEntryField.text = ""
        pinResultLabel.text = ""

        versionLabel.text = AppDelegate.getAppVersionFull()

        initFindMyLocation()

//        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.EditingChanged)
//        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.TouchUpInside)
    }

    override func viewWillAppear(animated: Bool) {
        NSLog("viewWillAppear")

        pinEntryField.becomeFirstResponder()
    }
    
    @IBAction func jetztOeffnenButtonPressed(sender: AnyObject) {
        NSLog("buttonPressed")

        var code = pinEntryField.text
        println("pin="+code)
        pinEntryField.resignFirstResponder()

        ergebnisLabel.text = "running"
        enableAll(false)

        Backend.doOpen(code, geoy:geoy, geox:geox,
            completionHandler: { (hasBeenOpened, info) -> () in

                println("call returned to ViewController.")

                dispatch_async(dispatch_get_main_queue(), {

                    self.pinEntryField.text = ""
                    
                    var waitSeconds: Int64 = 5;

                    if hasBeenOpened {
                        self.pinResultLabel.text = "";
                        self.ergebnisLabel.text = "!!!!! Tür ist offen !!!!!"
                        self.bgImage.alpha = 1.0;
                    }
                    else {
                        println(info)

                        if countElements(info) < 20 {
                            self.pinResultLabel.text = info;
                            self.ergebnisLabel.text = ""
                            waitSeconds = 1
                        }
                        else {
                            self.pinResultLabel.text = "";
                            self.ergebnisLabel.text = info
                        }
                    }

                    self.enableAll(true)

                    var dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, waitSeconds * Int64(NSEC_PER_SEC))
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                        println("jetzt Ergebnis ausblenden etc.")
                        self.ergebnisLabel.text = ""
                        self.bgImage.alpha = 0.7;
                        self.pinEntryField.becomeFirstResponder()
                    })
                    
                })
        })
    }

    func enableAll(on:Bool) {
        self.jetztOeffnenButton.enabled = on
        self.pinEntryField.enabled = on
        if (on) {
            self.pinEntryField.becomeFirstResponder()
        }
    }

    @IBAction func pinEntryEditingDidEnd(sender: AnyObject) {
        NSLog("pinEntryEditingDidEnd")
    }

    @IBAction func pinEntryValueChanged(sender: AnyObject) {
        NSLog("pinEntryValueChanged value="+pinEntryField.text)

        if countElements(pinEntryField.text) >= 4 {
            jetztOeffnenButtonPressed(sender)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func cancelToMainViewController(segue:UIStoryboardSegue) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func saveRegistration(segue:UIStoryboardSegue) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func initFindMyLocation() {
        NSLog("initFindMyLocation")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        gotGeolocation = false
        self.enableAll(self.gotGeolocation)
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {

        if (manager.location.horizontalAccuracy < NEEDED_ACCURACY_IN_M && manager.location.horizontalAccuracy < NEEDED_ACCURACY_IN_M) {
            self.geoy = manager.location.coordinate.latitude
            self.geox = manager.location.coordinate.longitude
            if (!self.gotGeolocation) {
                NSLog("didUpdateLocations ok: geoy=%f, geox=%f", self.geoy, self.geox)
                dispatch_async(dispatch_get_main_queue(), {
                    self.enableAll(true)
                })
            }
            self.gotGeolocation = true
        }
        else {
            if (self.gotGeolocation) {
                NSLog("didUpdateLocations ok: geoy=%f, geox=%f", self.geoy, self.geox)
                dispatch_async(dispatch_get_main_queue(), {
                    self.enableAll(false)
                })
                self.gotGeolocation = false
            }
        }
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("Error while updating location " + error.localizedDescription)
    }
}

