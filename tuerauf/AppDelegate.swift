//
//  AppDelegate.swift
//  tuerauf
//
//  Created by Dirk Steinkopf on 04.01.15.
//  Copyright (c) 2016 Dirk Steinkopf. All rights reserved.
//

import UIKit


#if DEBUG
    private let urlScheme = "tuerauftest"
#else
    private let urlScheme = "tuerauf"
#endif


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var mainViewController: ViewController?

    private var _userRegistration: UserRegistration! = UserRegistration()


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        // remove stored PIN - don't persist user's PIN
        NSUserDefaults.standardUserDefaults().removeObjectForKey("tueraufPIN")

        if let tryMainViewController = self.window?.rootViewController as? ViewController {
            self.mainViewController = tryMainViewController
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        NSLog("handleOpenURL url=%@", url)
        if url.scheme != urlScheme {
            return false
        }

        if url.query == nil {
            NSLog("found no query")
            return false
        }
        NSLog("url.query=%@", url.query!)

        let parts = url.query!.characters.split{$0 == "/"}.map(String.init)

        if parts.count == 1 && url.query!.hasPrefix("pin=") {
            let pinParts = url.query!.characters.split{$0 == "="}.map(String.init)
            if pinParts.count == 2 {
                let pin = pinParts[1]
                NSLog("got pin \(pin)")
                jumpToMainViewWithPin(pin)
            }
        }

        if parts.count != 2 {
            NSLog("found \(parts.count) query parts instead of expected 2")
            return false
        }

        for part in parts {
            NSLog("part=%@", part)
        }

        Backend.sharedInstance.configBaseUrl = parts[0].stringByRemovingPercentEncoding
        Backend.sharedInstance.configAppSecret = parts[1].stringByRemovingPercentEncoding

        // Erfolgsmeldung:
        let alert = UIAlertController(title: "Hat geklappt", message: "Die App ist nun konfiguriert.",
            preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { action in
            NSLog("ok pressed")
        }))
        self.window?.rootViewController!.presentViewController(alert, animated: true, completion: nil)

        return true
    }

    class func getAppVersionFull() -> String! {
        let infoDict: NSDictionary? = NSBundle.mainBundle().infoDictionary
        let revDetails: String? = infoDict?["CFBundleVersionDetails"] as? String // CFBundleVersionDetails = our own key
        let version:    String? = infoDict?["CFBundleShortVersionString"] as? String

        var fullVersion = String(format:"%@ (%@)",
            version == nil ? "?" : version!,
            revDetails == nil ? "??" : revDetails!)
        #if DEBUG
            fullVersion += " test"
        #endif
        NSLog("fullVersion="+fullVersion)
        return fullVersion
    }

    internal var userRegistration: UserRegistration {
        get {
            return _userRegistration
        }
    }

    func jumpToMainViewWithPin(pin: String) {
        NSLog("jumpToMainViewWithPin \(pin)")
        if pin.characters.count == 4 {
            mainViewController?.pinEntryField.text = pin
            mainViewController?.jetztOeffnenButtonPressed(self)
        }
    }
}

