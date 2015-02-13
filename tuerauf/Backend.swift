//
//  Backend.swift
//  Tür auf
//
//  Created by Dirk Steinkopf on 03.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import Foundation

private let baseUrl = "https://backend.steinkopf.net:39931/tuerauf/"
private let appsecretParam = "appsecret=plUwPcIE82vKwHUVnGiS4o5J6o"
private let debugParam = "&debug=1"
private var lastCall = Dictionary<String,NSDate>()


class Backend {

    class func doOpen(code: String, geoy: Double, geox: Double, installationid: String,
        completionHandler: (hasBeenOpened: Bool, info: String) -> ())
    {
        let geoy_str = String(format:"%f", geoy)
        let geox_str = String(format:"%f", geox)
        let urlString = String(format:"%@tuerauf.php?%@&geoy=%@&geox=%@&installationid=%@&pin=%@",
            baseUrl, appsecretParam, geoy_str, geox_str, installationid, code)

        bgRunDataTaskWithURL("doOpen", urlStringParam:urlString) {
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

    class func checkloc(geoy: Double, geox: Double, installationid: String,
                        completionHandler: (isNear: Bool, info: String) -> ())
    {
        let geoy_str = String(format:"%f", geoy)
        let geox_str = String(format:"%f", geox)
        let urlString = String(format:"%@checkloc.php?%@&geoy=%@&geox=%@&installationid=%@",
            baseUrl, appsecretParam, geoy_str, geox_str, installationid)

        bgRunDataTaskWithURL("checkloc", urlStringParam:urlString) {
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

    class func registerUser(username: String, pin: String, installationid: String,
        completionHandler: (hasBeenSaved: Bool, info: String) -> ())
    {
        let urlString = String(format:"%@register_user.php?%@&installationid=%@&name=%@&pin=%@",
            baseUrl,
            appsecretParam,
            installationid,
            username.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!,
            pin.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        )

        bgRunDataTaskWithURL("registerUser", urlStringParam:urlString) {
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

    private class func bgRunDataTaskWithURL(callType: String, urlStringParam: String, completionHandler: ((NSData!, String!) -> Void)) {

        if let lastCallThisType = lastCall[callType] {
            if -lastCallThisType.timeIntervalSinceNow < 3 {
                // NSLog("lastCall[\(callType)].timeIntervalSinceNow < 3 => return")
                return
            }
        }
        lastCall[callType] = NSDate()

        // NSLog("running \(callType)]")

        var urlString = urlStringParam
        #if DEBUG
            urlString += debugParam // wird (noch) nicht ausgewertet
        #endif
        let url = NSURL(string: urlString)
        NSLog("calling url="+urlString)

        let session = self.getSession()

        let task = session.dataTaskWithURL(url!) {
            (data, response, error) in

            if (error != nil) {
                var infoString = error.userInfo?.description
                completionHandler(data, infoString!)
                return
            }

            if !(response is NSHTTPURLResponse) {
                completionHandler(data, "no http response")
                return
            }

            let httpresponse = response as NSHTTPURLResponse

            if httpresponse.statusCode != 200 {
                completionHandler(data, "falscher Statuscode \(httpresponse.statusCode)")
                return
            }

            // mit dem Aufruf an sich ist alles ok
            completionHandler(data, nil)

            // NSLog("running \(callType)] done")
        }

        task.resume()
        session.finishTasksAndInvalidate()
    }

    private class func getSession() -> NSURLSession! {
        var config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = 15

        let session = NSURLSession(configuration: config)
        return session
    }
}