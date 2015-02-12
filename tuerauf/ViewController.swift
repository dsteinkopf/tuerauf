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
    private var isNear = false

    private var userRegistration: UserRegistration?

    private var textToShowInErgebnisLabel:String? = nil
    private var specialTextToShowInErgebnisLabel:String? = nil // "überschreibt" specialTextToShowInErgebnisLabel


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

        updateErgebnisLabel()
        pinEntryField.text = ""
        pinResultLabel.text = ""
    }

    override func viewWillAppear(animated: Bool) {
        NSLog("viewWillAppear")

        initFindMyLocation()
    }

    override func viewDidAppear(animated: Bool) {
        checkToEnableAll()
    }
    
    @IBAction func jetztOeffnenButtonPressed(sender: AnyObject) {
        NSLog("buttonPressed")

        var code = pinEntryField.text
        println("pin="+code)
        pinEntryField.resignFirstResponder()

        self.updateErgebnisLabel(text:"running")
        enableAll(false)

        Backend.doOpen(code, geoy:geoy, geox:geox, installationid:userRegistration!.installationId,
            completionHandler: { (hasBeenOpened, info) -> () in

                println("call to Backend.doOpen returned to ViewController.")

                dispatch_async(dispatch_get_main_queue(), {

                    self.pinEntryField.text = ""
                    
                    var waitSeconds: Int64 = 5;

                    if hasBeenOpened {
                        self.pinResultLabel.text = "";
                        self.updateErgebnisLabel(text:"!!!!! Tür ist offen !!!!!")
                        self.bgImage.alpha = 1.0;
                    }
                    else {
                        println(info)

                        if countElements(info) < 20 {
                            self.pinResultLabel.text = info
                            self.updateErgebnisLabel(text:"")
                            waitSeconds = 1
                        }
                        else {
                            self.pinResultLabel.text = "";
                            self.updateErgebnisLabel(text:info)
                        }
                    }

                    var dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, waitSeconds * Int64(NSEC_PER_SEC))
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                        println("jetzt Ergebnis ausblenden etc.")
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
        self.enableAll(self.gotGeolocation && self.userRegistration!.registered!)
        // NSLog("checkToEnableAll: self.gotGeolocation=%@, registered=%@", self.gotGeolocation ? "t":"f", self.userRegistration!.registered! ? "t":"f")
        if !self.userRegistration!.registered! {
            updateErgebnisLabel(specialText: "Nicht registriert.\nBitte auf Zahnrad klicken, Name eingeben und speichern!")
        }
        else if !self.gotGeolocation {
            updateErgebnisLabel(specialText: "Handy-Ortung nicht bereit oder genau genug.")
        }
        else {
            updateErgebnisLabel(specialText: "")
        }
        if self.gotGeolocation && self.isNear {
            pinEntryField.backgroundColor = UIColor.greenColor()
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

        gotGeolocation = false

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        self.checkToEnableAll()
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {

        // NSLog("didUpdateLocations: geoy=%f, geox=%f accuracy=%f m", self.geoy, self.geox, manager.location.horizontalAccuracy)

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
        println("Error while updating location " + error.localizedDescription)
    }

    private func checklocation() {

        Backend.checkloc(geoy, geox:geox, installationid:userRegistration!.installationId,
            completionHandler: { (isNear, info) -> () in

                println("call to Backend.checkloc returned to ViewController. isNear=\(isNear)")

                self.isNear = isNear

                dispatch_async(dispatch_get_main_queue(), {
                    self.checkToEnableAll()
                })
        })
    }
}

