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
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    private let locationManager = CLLocationManager()
    private let NEEDED_ACCURACY_IN_M = 75.0
    private let TIME_TO_KEEP_NEAR_LOCATION = 60.0 // sek.

    private var isRunning = false
    private var geoy: Double = 0.0
    private var geox: Double = 0.0
    private var gotGeolocation = false
    private var isNear = false
    private var nextTimeChecklocation: NSDate? = nil

    private var userRegistration: UserRegistration?

    private var textToShowInErgebnisLabel:String? = nil
    private var specialTextToShowInErgebnisLabel:String? = nil // "überschreibt" specialTextToShowInErgebnisLabel


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        userRegistration = appDelegate.userRegistration

        fillViews()

//        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.EditingChanged)
//        pinEntryField.addTarget(self, action: "pinEntryValueChanged:", forControlEvents: UIControlEvents.TouchUpInside)
    }

    private func fillViews() {
        versionLabel.text = AppDelegate.getAppVersionFull()

        updateErgebnisLabel()
        pinEntryField.text = ""
        pinResultLabel.text = ""

        self.activityHandler(false)
    }

    override func viewWillAppear(animated: Bool) {
        NSLog("viewWillAppear")

        initFindMyLocation()
    }

    override func viewDidAppear(animated: Bool) {
        NSLog("viewDidAppear")

        checkToEnableAll()
    }

    private func activityHandler(isActive: Bool) {

        dispatch_async(dispatch_get_main_queue(), {
            if (isActive) {
                self.activityIndicator.hidden = false
                self.activityIndicator.startAnimating()
            }
            else {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.hidden = true
            }
        })
    }
    
    @IBAction func jetztOeffnenButtonPressed(sender: AnyObject) {
        NSLog("buttonPressed")

        var code = pinEntryField.text
        NSLog("pin="+code)
        pinEntryField.resignFirstResponder()

        self.updateErgebnisLabel(text:"running")
        self.isRunning = true
        self.checkToEnableAll()

        let installationId = self.userRegistration!.installationId
        if self.userRegistration!.error != nil {
            var alert = UIAlertController(title: "Problem", message: "installationId nicht gespeichert",
                preferredStyle: UIAlertControllerStyle.Alert)
            return
        }

        Backend.sharedInstance.doOpen(code, geoy:geoy, geox:geox, installationid:userRegistration!.installationId,
            activityHandler:activityHandler,
            completionHandler: { (hasBeenOpened, info) -> () in

                NSLog("call to Backend.doOpen returned to ViewController.")

                dispatch_async(dispatch_get_main_queue(), {

                    self.isRunning = false
                    self.pinEntryField.text = ""
                    self.checkToEnableAll()

                    var waitSeconds = 5.0;

                    if hasBeenOpened {
                        self.pinResultLabel.text = "";
                        self.updateErgebnisLabel(text:"!!!!! Tür ist offen !!!!!")
                        self.bgImage.alpha = 1.0;
                    }
                    else {
                        NSLog(info)

                        if count(info) < 20 {
                            self.pinResultLabel.text = info
                            self.updateErgebnisLabel(text:"")
                            waitSeconds = 0.1
                        }
                        else {
                            self.pinResultLabel.text = "";
                            self.updateErgebnisLabel(text:info)
                        }
                    }

                    var dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(waitSeconds * Double(NSEC_PER_SEC)))
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                        NSLog("jetzt Ergebnis ausblenden etc.")
                        self.updateErgebnisLabel(text:"")
                        self.bgImage.alpha = 0.7;

                        self.checkToEnableAll()
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
        self.enableAll(!self.isRunning
                        && self.gotGeolocation
                        && self.userRegistration!.registered!
                        && Backend.sharedInstance.isConfigured()
                        && self.textToShowInErgebnisLabel == nil)
        // NSLog("checkToEnableAll: self.gotGeolocation=%@, registered=%@", self.gotGeolocation ? "t":"f", self.userRegistration!.registered! ? "t":"f")
        if !Backend.sharedInstance.isConfigured() {
            updateErgebnisLabel(specialText: "App nicht konfiguriert: Fragen Sie Ihren Admin nach dem Config-Link.")
        }
        else if !self.userRegistration!.registered! {
            updateErgebnisLabel(specialText: "Nicht registriert.\nBitte auf Zahnrad klicken, Name eingeben und speichern!")
        }
        else if !self.gotGeolocation {
            updateErgebnisLabel(specialText: "Handy-Ortung nicht bereit oder genau genug.")
        }
        else {
            updateErgebnisLabel(specialText: "")
        }
        if self.gotGeolocation && self.isNear {
            pinEntryField.backgroundColor = UIColor(red: 153.0/255, green: 255.0/255, blue: 204.0/255, alpha: 0.7)
        }
        else {
            pinEntryField.backgroundColor = UIColor.clearColor()
        }
    }

    // Zeigt den specialText bzw. text an. Wenn einer nil ist, bleibt der alte Wert
    // Wenn specialText == nil wird self.textToShowInErgebnisLabel angezeigt.
    private func updateErgebnisLabel(text:String? = nil, specialText: String? = nil) {

        if text != nil {
            self.textToShowInErgebnisLabel = text!.isEmpty ? nil : text!
        }
        if specialText != nil {
            self.specialTextToShowInErgebnisLabel = specialText!.isEmpty ? nil : specialText!
        }
        dispatch_async(dispatch_get_main_queue(), {
            if (self.specialTextToShowInErgebnisLabel != nil) {
                self.ergebnisLabel.text = self.specialTextToShowInErgebnisLabel
            }
            else if (self.textToShowInErgebnisLabel != nil) {
                    self.ergebnisLabel.text = self.textToShowInErgebnisLabel
            }
            else {
                self.ergebnisLabel.text = ""
            }
        })
    }

    @IBAction func pinEntryEditingDidEnd(sender: AnyObject) {
        NSLog("pinEntryEditingDidEnd")
    }

    @IBAction func pinEntryValueChanged(sender: AnyObject) {
        NSLog("pinEntryValueChanged value="+pinEntryField.text)

        if count(pinEntryField.text) >= 4 {
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

        self.checkToEnableAll()
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {

        // NSLog("didUpdateLocations: geoy=%f, geox=%f accuracy=%f m", self.geoy, self.geox, manager.location.horizontalAccuracy)

        if self.nextTimeChecklocation != nil && !self.nextTimeChecklocation!.timeIntervalSinceNow.isSignMinus {
            // NSLog("nextTimeChecklocation in future: no checklocation")
            return
        }

        if (manager.location.horizontalAccuracy < NEEDED_ACCURACY_IN_M) {
            self.geoy = manager.location.coordinate.latitude
            self.geox = manager.location.coordinate.longitude

            // NSLog("didUpdateLocations here: geoy=%f, geox=%f", self.geoy, self.geox)

            if !gotGeolocation { // geoLocation ist also jetzt neu
                self.gotGeolocation = true

                dispatch_async(dispatch_get_main_queue(), {
                    self.checkToEnableAll()
                })
            }

            self.checklocation()
        }
        else {
            NSLog("manager.location.horizontalAccuracy = %f", manager.location.horizontalAccuracy)

            if self.gotGeolocation { // geoLocation gerade verloren
                // NSLog("didUpdateLocations away: geoy=%f, geox=%f", self.geoy, self.geox)
                self.gotGeolocation = false

                dispatch_async(dispatch_get_main_queue(), {
                    self.checkToEnableAll()
                })
            }
        }
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        NSLog("Error while updating location " + error.localizedDescription)
    }

    private func checklocation() {

        let checkGeoy = geoy
        let checkGeox = geox

        Backend.sharedInstance.checkloc(checkGeoy, geox:checkGeox, installationid:userRegistration!.installationId,
            activityHandler:activityHandler,
            completionHandler: { (isNear, info) -> () in

                NSLog("call to Backend.checkloc returned to ViewController. isNear=\(isNear)")

                self.isNear = isNear

                if (self.isNear) {
                    // wenn guter Ort gefunden, dann erst nach bestimmter Zeit wieder probieren
                    self.nextTimeChecklocation = NSDate().dateByAddingTimeInterval(self.TIME_TO_KEEP_NEAR_LOCATION)
                    self.geoy = checkGeoy
                    self.geox = checkGeox
                }

                dispatch_async(dispatch_get_main_queue(), {
                    self.checkToEnableAll()
                })
        })
    }
}

