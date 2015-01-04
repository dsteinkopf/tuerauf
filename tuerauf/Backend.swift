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

        var baseUrl = "http://arduino.steinkopf.net/"

        var urlString = baseUrl + code;
        var url = NSURL(string: urlString)

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

            // alles ok

            var dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
            // println("http result:" + dataString!)

            var wasOpened = dataString?.containsString("OFFEN") != nil;

            completionHandler(hasBeenOpened: wasOpened, info: "ok")
        }
        
        task.resume()
    }
}