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

            var dataStringNS = NSString(data: data, encoding: NSUTF8StringEncoding)
            var dataString = String(dataStringNS!)
            println("http result:" + dataString)

            var lines = dataString.componentsSeparatedByString("\n")
            var resultLine: String?
            for line in lines {
                if line.hasPrefix("<") {
                    continue
                }
                if let range = line.rangeOfString("<") {
                    resultLine = line.substringToIndex(range.startIndex)
                }
            }

            let hasBeenOpened: Bool = resultLine?.rangeOfString("OFFEN") != nil
            // let gotDynCode: Bool =    resultLine!.hasPrefix("dyn_code ")
            // let badFixedPin: Bool   = resultLine?.rangeOfString("bad fixed_pin") != nil

            completionHandler(hasBeenOpened: hasBeenOpened, info: resultLine!)
        }
        
        task.resume()
    }
}