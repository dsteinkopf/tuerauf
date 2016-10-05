//
//  TodayViewController.swift
//  tawidget
//
//  Created by Dirk Steinkopf on 02.10.16.
//  Copyright © 2016 Dirk Steinkopf. All rights reserved.
//

import UIKit
import NotificationCenter

#if DEBUG
    private let urlScheme = "tuerauftest"
#else
    private let urlScheme = "tuerauf"
#endif


class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet var startButton: UIButton!

    @IBOutlet var button0: UIButton!
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    @IBOutlet var button3: UIButton!
    @IBOutlet var button5: UIButton!
    @IBOutlet var button4: UIButton!
    @IBOutlet var button6: UIButton!
    @IBOutlet var button7: UIButton!
    @IBOutlet var button8: UIButton!
    @IBOutlet var button9: UIButton!

    @IBOutlet var enteredPinTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        enteredPinTextField.text = ""
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }

    @IBAction func startButtonAction(sender: UIButton) {
        NSLog("startButtonAction");
        // let options = [UIApplicationOpenURLOptionUniversalLinksOnly : true]
        let url = NSURL(string: urlScheme + "://")!
        self.extensionContext?.openURL(url, completionHandler: nil)
    }

    func numberButtonPressed(number: String, sender: AnyObject) {
        NSLog("number=%@", number)

        enteredPinTextField.text?.appendContentsOf(number)
        enteredPinTextField.becomeFirstResponder()

        let pressedButton = sender as! UIButton
        pressedButton.selected = true
        let waitTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
        dispatch_after(waitTime, dispatch_get_main_queue(), {
            pressedButton.selected = false
        })

        if enteredPinTextField.text?.characters.count >= 4 {
            let url = NSURL(string: urlScheme + ":///?pin=" + enteredPinTextField.text!)!
            self.extensionContext?.openURL(url, completionHandler: { (success) in
                let waitTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
                dispatch_after(waitTime, dispatch_get_main_queue(), {
                    self.enteredPinTextField.text = ""
                })
            })
        }
    }

    @IBAction func button1Action(sender: AnyObject) {
        numberButtonPressed("1", sender: sender)
    }
    @IBAction func button2Action(sender: AnyObject) {
        numberButtonPressed("2", sender: sender)
    }
    @IBAction func button3Action(sender: AnyObject) {
        numberButtonPressed("3", sender: sender)
    }
    @IBAction func button4Action(sender: AnyObject) {
        numberButtonPressed("4", sender: sender)
    }
    @IBAction func button5Action(sender: AnyObject) {
        numberButtonPressed("5", sender: sender)
    }
    @IBAction func button6Action(sender: AnyObject) {
        numberButtonPressed("6", sender: sender)
    }
    @IBAction func button7Action(sender: AnyObject) {
        numberButtonPressed("7", sender: sender)
    }
    @IBAction func button8Action(sender: AnyObject) {
        numberButtonPressed("8", sender: sender)
    }
    @IBAction func button9Action(sender: AnyObject) {
        numberButtonPressed("9", sender: sender)
    }
    @IBAction func button0Action(sender: AnyObject) {
        numberButtonPressed("0", sender: sender)
    }
}
