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

    private let locationManager = CLLocationManager()
    private let NEEDED_ACCURACY_IN_M = 75.0
    private var geoy: Double = 0.0
    private var geox: Double = 0.0
    private var gotGeolocation = false

    private var userRegistration: UserRegistration?


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        userRegistration = appDelegate.userRegistration

        fillViews()

//        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.EditingChanged)
//        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.TouchUpInside)
    }

    private func fillViews() {
        versionLabel.text = AppDelegate.getAppVersionFull()

        ergebnisLabel.text = ""
        pinEntryField.text = ""
        pinResultLabel.text = ""
    }

    override func viewWillAppear(animated: Bool) {
        NSLog("viewWillAppear")

        pinEntryField.becomeFirstResponder()

        initFindMyLocation()
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

                    self.checkToEnableAll()

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

    private func enableAll(on:Bool) {
        self.jetztOeffnenButton.enabled = on
        self.pinEntryField.enabled = on
        if (on) {
            self.pinEntryField.becomeFirstResponder()
        }
        else {
            self.pinEntryField.resignFirstResponder()
        }
    }

    private func checkToEnableAll() {
        self.enableAll(self.gotGeolocation && self.userRegistration!.registered!)
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

        self.checkToEnableAll()
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {

        // NSLog("didUpdateLocations: geoy=%f, geox=%f accuracy=%f m", self.geoy, self.geox, manager.location.horizontalAccuracy)

        if (manager.location.horizontalAccuracy < NEEDED_ACCURACY_IN_M) {
            self.geoy = manager.location.coordinate.latitude
            self.geox = manager.location.coordinate.longitude
            self.gotGeolocation = true

            // NSLog("didUpdateLocations here: geoy=%f, geox=%f", self.geoy, self.geox)
            dispatch_async(dispatch_get_main_queue(), {
                self.checkToEnableAll()
            })
        }
        else {
            if (self.gotGeolocation) {
                // NSLog("didUpdateLocations away: geoy=%f, geox=%f", self.geoy, self.geox)
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

