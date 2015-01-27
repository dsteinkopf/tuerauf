//
//  SettingsViewController.swift
//  tuerauf
//
//  Created by Dirk Steinkopf on 26.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            usernameTextField.becomeFirstResponder()
        }
    }

    @IBAction func saveButtonPressed(sender: AnyObject) {
        NSLog("saveButtonPressed");

        self.activityIndicator.startAnimating()

        Backend.registerUser(usernameTextField.text,
            completionHandler: { (hasBeenSaved, info) -> () in

                NSLog("registerUser returned: hasBeenSaved:%@ info=%@", hasBeenSaved, info)
                dispatch_async(dispatch_get_main_queue(), {
                        self.activityIndicator.stopAnimating()
                    })

                if hasBeenSaved {
                    self.performSegueWithIdentifier("saveRegistration", sender: self)
                }
                else {
                    var alert = UIAlertController(title: "Nicht registriert", message: info, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
        })
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        NSLog("shouldPerformSegueWithIdentifier: %@", identifier!);
        return true;
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "cancelToMainViewController" {
            NSLog("SettingsViewController.cancelToMainViewController")
        }
        else if segue.identifier == "saveRegistration" {
            NSLog("SettingsViewController.saveRegistration")
            // let destinationViewController = segue.destinationViewController

        }
    }
}
