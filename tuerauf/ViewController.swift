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


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ergebnisLabel.text = ""
    }
    
    @IBAction func jetztOeffnenButtonPressed(sender: AnyObject) {
        NSLog("buttonPressed")

        ergebnisLabel.text = "running"
        jetztOeffnenButton.enabled = false

        var code = "abc"

        Backend.doOpen(code,
            completionHandler: { (hasBeenOpened, info) -> () in

                println("returned.")

                dispatch_async(dispatch_get_main_queue(), {

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

