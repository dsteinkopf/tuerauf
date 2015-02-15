//
//  UserRegistration.swift
//  tuerauf
//
//  Created by Dirk Steinkopf on 27.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import Foundation


class UserRegistration {

    private var _username: String?
    private var _pin: String?
    private var _installationId: String?
    private var _registered: Bool?

    private let userdefaults = NSUserDefaults.standardUserDefaults()


    var username: String! {
        get {
            if _username != nil {
                return _username!
            }
            _username = userdefaults.stringForKey("tueraufUsername")
            if _username != nil {
                return _username;
            }
            _username = ""
            return _username!
        }
        set {
            _username = newValue
            userdefaults.setObject(_username, forKey: "tueraufUsername")
        }
    }

    var pin: String! {
        get {
            if _pin != nil {
                return _pin!
            }
            _pin = userdefaults.stringForKey("tueraufPIN")
            if _pin != nil {
                return _pin;
            }
            _pin = ""
            return _pin!
        }
        set {
            _username = newValue
            userdefaults.setObject(_username, forKey: "tueraufPIN")
        }
    }

    var installationId: String! {
        get {
            if _installationId != nil {
                return _installationId!
            }
            _installationId = userdefaults.stringForKey("tueraufInstallationId")
            if _installationId != nil {
                return _installationId;
            }
            _installationId = NSUUID().UUIDString
            userdefaults.setObject(_installationId, forKey: "tueraufInstallationId")
            return _installationId!
        }
    }

    var registered: Bool! {
        get {
            if _registered != nil {
                return _registered!
            }
            _registered = userdefaults.boolForKey("tueraufRegistered")
            return _registered!
        }
        set {
            _registered = newValue
            userdefaults.setBool(_registered!, forKey: "tueraufRegistered")
        }
    }

    init() {
        // leer
    }
}
