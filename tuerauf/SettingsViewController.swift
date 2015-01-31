//
//  SettingsViewController.swift
//  tuerauf
//
//  Created by Dirk Steinkopf on 26.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var usernameCell: UITableViewCell!
    @IBOutlet var pinEntryCell: UITableViewCell!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var pinEntryTextField: UITextField!

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
        pinEntryTextField.addTarget(self, action: "pinEntryTextFieldValueChanged:", forControlEvents: UIControlEvents.EditingChanged)

        fillViews()
}

    private func fillViews() {
        usernameTextField.text = userRegistration!.username;
        pinEntryTextField.text = userRegistration!.pin;
        usernameCell.accessoryType = userRegistration!.registered! ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None;
        pinEntryCell.accessoryType = userRegistration!.registered! ? UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None;

        usernameTextField.becomeFirstResponder()
    }

    private func saveUservalues() {
        userRegistration!.username = usernameTextField.text
        userRegistration!.pin = pinEntryTextField.text
        userRegistration!.registered = false
        self.usernameCell.accessoryType = UITableViewCellAccessoryType.None;
        self.pinEntryCell.accessoryType = UITableViewCellAccessoryType.None;
    }

    private func saveRegistration() {
        userRegistration!.username = usernameTextField.text
        userRegistration!.pin = pinEntryTextField.text
        userRegistration!.registered = true
        self.usernameCell.accessoryType = UITableViewCellAccessoryType.Checkmark;
        self.pinEntryCell.accessoryType = UITableViewCellAccessoryType.Checkmark;
    }

    @IBAction func usernameTextFieldValueChanged(sender: AnyObject) {
        NSLog("usernameTextFieldValueChanged");
        self.usernameCell.accessoryType = UITableViewCellAccessoryType.None;
        self.pinEntryCell.accessoryType = UITableViewCellAccessoryType.None;
    }

    @IBAction func pinEntryTextFieldValueChanged(sender: AnyObject) {
        NSLog("pinEntryTextFieldValueChanged");
        self.usernameCell.accessoryType = UITableViewCellAccessoryType.None;
        self.pinEntryCell.accessoryType = UITableViewCellAccessoryType.None;
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            usernameTextField.becomeFirstResponder()
        }
    }

    @IBAction func saveButtonPressed(sender: AnyObject) {
        NSLog("saveButtonPressed");

        self.activityIndicator.startAnimating()

        Backend.registerUser(usernameTextField.text, pin:pinEntryTextField.text, installationid: self.userRegistration!.installationId,
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
                        self.saveUservalues() // username/Pin bleiben erhalten, auch wenn reg. fehlschlägt
                        
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
