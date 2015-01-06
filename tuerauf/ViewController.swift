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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ergebnisLabel.text = ""
        pinEntryField.text = ""
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
                    
                    if hasBeenOpened {
                        self.ergebnisLabel.text = "offen"
                    }
                    else {
                        self.ergebnisLabel.text = info
                        println(info)
                    }

                    self.jetztOeffnenButton.enabled = true

                    var dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
                    dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                        self.ergebnisLabel.text = ""
                    })
                    
                })
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

