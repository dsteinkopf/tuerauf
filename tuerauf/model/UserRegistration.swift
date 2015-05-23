//
//  UserRegistration.swift
//  tuerauf
//
//  Created by Dirk Steinkopf on 27.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import Foundation
import SwiftKeychain


class UserRegistration {

    private var _username: String?
    private var _pin: String?
    private var _installationId: String?
    private var _registered: Bool?

    private let userdefaults = NSUserDefaults.standardUserDefaults()
    private let keychain = Keychain()
    private let tueraufInstallationIdKey = GenericKey(keyName: "tueraufInstallationId")

    private var _error: NSError? = nil


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
            // no - don't persist user's PIN: _pin = userdefaults.stringForKey("tueraufPIN")
            // no - don't persist user's PIN: if _pin != nil {
            // no - don't persist user's PIN:     return _pin;
            // no - don't persist user's PIN: }
            _pin = ""
            return _pin!
        }
        set {
            _pin = newValue
            // no - don't persist user's PIN: userdefaults.setObject(_pin, forKey: "tueraufPIN")
        }
    }

    var installationId: String! {
        get {
            _error = nil;

            if _installationId != nil {
                return _installationId!
            }
            _installationId = userdefaults.stringForKey("tueraufInstallationId")
            if _installationId != nil {
                userdefaults.removeObjectForKey("tueraufInstallationId")
            }
            else if let installationId = keychain.get(tueraufInstallationIdKey).item?.value {
                _installationId = installationId as String
                return _installationId
            }
            else {
                _installationId = NSUUID().UUIDString
            }
            // store new key:
            tueraufInstallationIdKey.value = _installationId
            if let error = keychain.add(tueraufInstallationIdKey) {
                _error = error
            }
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

    var error: NSError? {
        get {
            return _error;
        }
    }

    init() {
        // leer
    }
}
