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
    @IBOutlet var usernameCell: UITableViewCell!

    private var userRegistration: UserRegistration?


    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        userRegistration = appDelegate.userRegistration

        usernameTextField.addTarget(self, action: "usernameTextFieldValueChanged:", forControlEvents: UIControlEvents.EditingChanged)

        fillViews()
}

    private func fillViews() {
        usernameTextField.text = userRegistration!.username;
        usernameCell.accessoryType = userRegistration!.registered! ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None;

        usernameTextField.becomeFirstResponder()
    }

    private func saveUsername() {
        userRegistration!.username = usernameTextField.text
        userRegistration!.registered = false
        self.usernameCell.accessoryType = UITableViewCellAccessoryType.None;
    }

    private func saveRegistration() {
        userRegistration!.username = usernameTextField.text
        userRegistration!.registered = true
        self.usernameCell.accessoryType = UITableViewCellAccessoryType.Checkmark;
    }

    @IBAction func usernameTextFieldValueChanged(sender: AnyObject) {
        NSLog("usernameTextFieldValueChanged");
        self.usernameCell.accessoryType = UITableViewCellAccessoryType.None;
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            usernameTextField.becomeFirstResponder()
        }
    }

    @IBAction func saveButtonPressed(sender: AnyObject) {
        NSLog("saveButtonPressed");

        self.activityIndicator.startAnimating()

        Backend.registerUser(usernameTextField.text, installationid: self.userRegistration!.installationId,
            completionHandler: { (hasBeenSaved, info) -> () in

                NSLog("registerUser returned: hasBeenSaved:%@ info=%@", hasBeenSaved, info)
                dispatch_async(dispatch_get_main_queue(), {

                    self.activityIndicator.stopAnimating()

                    if hasBeenSaved {
                        self.saveRegistration()

                        var alert = UIAlertController(title: "Alles gut", message: "Deine Info ist gespeichert. Bitte Admin Bescheid geben.",
                            preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
                            NSLog("ok pressed - now perform segue")

                            self.performSegueWithIdentifier("saveRegistration", sender: self)
                        }))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    else {
                        self.saveUsername() // username bleibt erhalten, auch wenn reg. fehlschlägt
                        
                        var alert = UIAlertController(title: "Nicht registriert", message: info, preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                })
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
