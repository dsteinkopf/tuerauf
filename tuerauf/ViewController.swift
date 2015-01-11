//
//  ViewController.swift
//  tuerauf
//
//  Created by Dirk Steinkopf on 04.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var jetztOeffnenButton: UIButton!
    @IBOutlet var ergebnisLabel: UILabel!
    @IBOutlet var pinEntryField: UITextField!
    @IBOutlet var bgImage: UIImageView!
    @IBOutlet var pinResultLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ergebnisLabel.text = ""
        pinEntryField.text = ""
        pinResultLabel.text = ""

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
        jetztOeffnenButton.enabled = false

        Backend.doOpen(code,
            completionHandler: { (hasBeenOpened, info) -> () in

                println("call returned to ViewController.")

                dispatch_async(dispatch_get_main_queue(), {

                    self.pinEntryField.text = ""
                    
                    var waitSeconds: Int64 = 5;

                    if hasBeenOpened {
                        self.ergebnisLabel.text = "!!!!! Tür ist offen !!!!!"
                        self.bgImage.alpha = 1.0;
                        self.pinResultLabel.text = ""
                    }
                    else {
                        println(info)

                        if info.rangeOfString("dyn_code ") != nil {
                            self.pinResultLabel.text = info;
                            self.ergebnisLabel.text = ""
                            waitSeconds = 1
                        }
                        else {
                            self.ergebnisLabel.text = info
                        }
                    }

                    self.jetztOeffnenButton.enabled = true

                    var dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, waitSeconds * Int64(NSEC_PER_SEC))
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                        self.ergebnisLabel.text = ""
                        self.bgImage.alpha = 0.7;
                        self.pinEntryField.becomeFirstResponder()
                    })
                    
                })
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


}

