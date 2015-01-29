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


class Backend {

    class func doOpen(code: String, geoy: Double, geox: Double, installationid: String,
                        completionHandler: (hasBeenOpened: Bool, info: String) -> ())
    {
        let geoy_str = String(format:"%f", geoy)
        let geox_str = String(format:"%f", geox)
        var urlString = String(format:"%@tuerauf.php?%@&geoy=%@&geox=%@&installationid=%@&arduinoparam=%@",
            baseUrl, appsecretParam, geoy_str, geox_str, installationid, code)
        var url = NSURL(string: urlString)
        println("calling url="+urlString)

        let session = getSession()

        let task = session.dataTaskWithURL(url!) {
            (data, response, error) in

            // sleep(3)

            if (error != nil) {
                var infoString = error.userInfo?.description
                completionHandler(hasBeenOpened: false, info: infoString!)
                return
            }

            if !(response is NSHTTPURLResponse) {
                completionHandler(hasBeenOpened: false, info: "no http response")
                return
            }

            let httpresponse = response as NSHTTPURLResponse

            if httpresponse.statusCode != 200 {
                completionHandler(hasBeenOpened: false, info: "falscher Statuscode \(httpresponse.statusCode)")
                return
            }

            // mit dem Aufruf an sich ist alles ok

            let dataStringNS = NSString(data: data, encoding: NSUTF8StringEncoding)
            let dataString = String(dataStringNS!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            println("http result:" + dataString)

            let hasBeenOpened: Bool = dataString.rangeOfString("OFFEN") != nil
            // let gotDynCode: Bool =    dataString!.hasPrefix("dyn_code ")
            // let badFixedPin: Bool   = dataString?.rangeOfString("bad fixed_pin") != nil

            completionHandler(hasBeenOpened: hasBeenOpened, info: dataString)
        }
        
        task.resume()
    }

    class func registerUser(username: String, installationid: String,
        completionHandler: (hasBeenSaved: Bool, info: String) -> ())
    {
        let urlString = String(format:"%@register_user.php?%@&installationid=%@&name=%@",
            baseUrl, appsecretParam, installationid, username.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!)
        let url = NSURL(string: urlString)
        println("calling url="+urlString)

        let session = getSession()

        let task = session.dataTaskWithURL(url!) {
            (data, response, error) in

            // sleep(3)

            if (error != nil) {
                var infoString = error.userInfo?.description
                completionHandler(hasBeenSaved: false, info: infoString!)
                return
            }

            if !(response is NSHTTPURLResponse) {
                completionHandler(hasBeenSaved: false, info: "no http response")
                return
            }

            let httpresponse = response as NSHTTPURLResponse

            if httpresponse.statusCode != 200 {
                completionHandler(hasBeenSaved: false, info: "falscher Statuscode \(httpresponse.statusCode)")
                return
            }

            // mit dem Aufruf an sich ist alles ok

            let dataStringNS = NSString(data: data, encoding: NSUTF8StringEncoding)
            let dataString = String(dataStringNS!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            println("http result:" + dataString)

            let hasBeenSaved: Bool = dataString.rangeOfString("saved_waiting") != nil

            completionHandler(hasBeenSaved: hasBeenSaved, info: dataString)
        }
        
        task.resume()
    }

    private class func getSession() -> NSURLSession! {
        var config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = 15

        let session = NSURLSession(configuration: config)
        return session
    }
}