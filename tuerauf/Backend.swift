//
//  Backend.swift
//  Tür auf
//
//  Created by Dirk Steinkopf on 03.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import Foundation


private let _backendInstance = Backend()

private let debugParam = "&debug=1"

private let REQUEST_TIMEOUT: NSTimeInterval = 15 // seconds


class Backend {

    private let userdefaults = NSUserDefaults.standardUserDefaults()

    private var _configBaseUrl:String? = nil
    private var _configAppSecret:String? = nil
    private var lastCall = Dictionary<String,NSDate>()
    

    class var sharedInstance: Backend {
        return _backendInstance
    }

    init() {
        // leer
    }

    var configBaseUrl: String? {
        get {
            if _configBaseUrl != nil {
                return _configBaseUrl
            }
            _configBaseUrl = userdefaults.stringForKey("tueraufConfigBaseUrl")
            return _configBaseUrl
        }
        set {
            _configBaseUrl = newValue
            NSLog("set _configBaseUrl \(_configBaseUrl)")
            userdefaults.setObject(_configBaseUrl, forKey: "tueraufConfigBaseUrl")
        }
    }

    var configAppSecret: String? {
        get {
            if _configAppSecret != nil {
                return _configAppSecret
            }
            _configAppSecret = userdefaults.stringForKey("tueraufConfigAppSecret")
            return _configAppSecret
        }
        set {
            _configAppSecret = newValue
            NSLog("set _configAppSecret \(_configAppSecret)")
            userdefaults.setObject(_configAppSecret, forKey: "tueraufConfigAppSecret")
        }
    }

    func isConfigured() -> Bool {
        return configAppSecret != nil && (configAppSecret!).characters.count > 1
            && configBaseUrl != nil && (configBaseUrl!).characters.count > 1;
    }

    func doOpen(code: String, geoy: Double, geox: Double, installationid: String,
        activityHandler: (isActive: Bool) -> Void,
        completionHandler: (hasBeenOpened: Bool, info: String) -> ())
    {
        let geoy_str = String(format:"%f", geoy)
        let geox_str = String(format:"%f", geox)
        let urlString = String(format:"openDoor?geoy=%@&geox=%@&installationId=%@",
            geoy_str, geox_str, installationid)
        let bodyData = String(format:"pin=%@",
            code.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        )

        bgRunDataTaskWithURL("doOpen", urlStringParam:urlString, bodyData:bodyData, activityHandler:activityHandler) {
            (data, info) in

            // sleep(3)

            if info != nil {
                completionHandler(hasBeenOpened: false, info: info)
                return
            }

            // mit dem Aufruf an sich ist alles ok

            let dataStringNS = NSString(data: data, encoding: NSUTF8StringEncoding)
            let dataString = String(dataStringNS!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            NSLog("http result:" + dataString)

            let hasBeenOpened: Bool = dataString.rangeOfString("OFFEN") != nil
            // let gotDynCode: Bool =    dataString!.hasPrefix("dyn_code ")
            // let badFixedPin: Bool   = dataString?.rangeOfString("bad fixed_pin") != nil

            completionHandler(hasBeenOpened: hasBeenOpened, info: dataString)
        }
    }

    func checkloc(geoy: Double, geox: Double, installationid: String,
                        activityHandler: (isActive: Bool) -> Void,
                        completionHandler: (isNear: Bool, info: String) -> ())
    {
        let geoy_str = String(format:"%f", geoy)
        let geox_str = String(format:"%f", geox)
        let urlString = String(format:"checkLocation?geoy=%@&geox=%@&installationId=%@",
            geoy_str, geox_str, installationid)

        bgRunDataTaskWithURL("checkloc", urlStringParam:urlString, bodyData:nil, activityHandler:activityHandler) {
            (data, info) in

            // sleep(3)

            if info != nil {
                completionHandler(isNear: false, info: info)
                return
            }

            // mit dem Aufruf an sich ist alles ok

            let dataStringNS = NSString(data: data, encoding: NSUTF8StringEncoding)
            let dataString = String(dataStringNS!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            NSLog("http result:" + dataString)

            let isNear: Bool = dataString.rangeOfString("near") != nil
            // println("isNear:\(isNear)")

            completionHandler(isNear: isNear, info: dataString)
        }
    }

    private func dummyActivityHandler(isActive: Bool) {
        // empty
    }

    func registerUser(username: String, pin: String, installationid: String,
        completionHandler: (hasBeenSaved: Bool, info: String) -> ())
    {
        let urlString = String(format:"registerUser?installationId=%@&username=%@",
            installationid,
            username.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        )
        let bodyData = String(format:"pin=%@",
            pin.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        )


        bgRunDataTaskWithURL("registerUser", urlStringParam:urlString, bodyData:bodyData, activityHandler:dummyActivityHandler) {
            (data, info) in

            // sleep(3)

            if info != nil {
                completionHandler(hasBeenSaved: false, info: info)
                return
            }

            // mit dem Aufruf an sich ist alles ok

            let dataStringNS = NSString(data: data, encoding: NSUTF8StringEncoding)
            let dataString = String(dataStringNS!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            NSLog("http result:" + dataString)

            let hasBeenSaved: Bool = dataString.rangeOfString("saved") != nil

            completionHandler(hasBeenSaved: hasBeenSaved, info: dataString)
        }
    }

    private func bgRunDataTaskWithURL(callType: String,
                                        urlStringParam: String,
                                        bodyData: String?,
                                        activityHandler: (isActive: Bool) -> (),
                                        completionHandler: ((NSData!, String!) -> Void))
    {
        if !isConfigured() {
            completionHandler(nil, "App ist noch nicht konfiguriert")
            return
        }

        if let lastCallThisType = lastCall[callType] {
            if -lastCallThisType.timeIntervalSinceNow < 3 {
                // NSLog("lastCall[\(callType)].timeIntervalSinceNow < 3 => return")
                return
            }
        }
        lastCall[callType] = NSDate()

        // NSLog("running \(callType)]")

        // build urlString:
        var urlString = configBaseUrl! + urlStringParam

        #if DEBUG
            urlString += debugParam // wird (noch) nicht ausgewertet
        #endif
        let url: NSURL! = NSURL(string: urlString)
        NSLog("calling url="+urlString)

        // build bodyDataToPost:
        var bodyDataToPost = bodyData == nil ? "" : bodyData!;
        bodyDataToPost += (bodyDataToPost.characters.count > 0 ? "&" : "") + "appsecret=" + configAppSecret!
        NSLog("bodyDataToPost=%@", bodyDataToPost)

        // create request
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = bodyDataToPost.dataUsingEncoding(NSUTF8StringEncoding);
        request.timeoutInterval = REQUEST_TIMEOUT

        let session = self.getSession()

        activityHandler(isActive: true)

        let task = session.dataTaskWithRequest(request) {
            (data, response, error) in

            activityHandler(isActive: false)

            if (error != nil) {
                let infoString = error!.userInfo.description
                completionHandler(data, infoString)
                return
            }

            if !(response is NSHTTPURLResponse) {
                completionHandler(data, "no http response")
                return
            }

            let httpresponse = response as! NSHTTPURLResponse

            if httpresponse.statusCode != 200 {
                completionHandler(data, "Statuscode \(httpresponse.statusCode). Bitte den Server prüfen.")
                return
            }

            // mit dem Aufruf an sich ist alles ok
            completionHandler(data, nil)

            // NSLog("running \(callType)] done")
        }

        task.resume()
        session.finishTasksAndInvalidate()
    }

    private func getSession() -> NSURLSession! {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = REQUEST_TIMEOUT

        let session = NSURLSession(configuration: config)
        return session
    }
}