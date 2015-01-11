//
//  Backend.swift
//  Tür auf
//
//  Created by Dirk Steinkopf on 03.01.15.
//  Copyright (c) 2015 Dirk Steinkopf. All rights reserved.
//

import Foundation

class Backend {

    class func doOpen(code: String, completionHandler: (hasBeenOpened: Bool, info: String) -> ()) {

        var baseUrl = "http://arduino.steinkopf.net:1080/"

        var urlString = baseUrl + code;
        var url = NSURL(string: urlString)
        println("calling url="+urlString)

        var config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = 5

        var session = NSURLSession(configuration: config)

        let task = session.dataTaskWithURL(url!) {
            (data, response, error) in

            // sleep(1)

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
                completionHandler(hasBeenOpened: false, info: "falscher status code \(httpresponse.statusCode)")
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
}