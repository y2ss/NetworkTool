//
//  RxHTTP.swift
//  http
//
//  Created by y2ss on 2018/9/10.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import RxSwift



class RxHTTP: HTTPClientBase {
    
    private static var _instance = RxHTTP(timeout: 20)
    
    class var shared: RxHTTP {
        return _instance
    }
    
    private override init(timeout: TimeInterval) {
        super.init(timeout: timeout)
    }
    
    func requestJSON<S: HTTPType>(_ api: S, params: [String: Any]? = nil) -> Observable<JSON> {
        var url = api.baseURL
        if let _url = URL(string: api.baseURL.absoluteString + api.path) {
            url = _url
        }
        return self
            ._requestJSON(url,
                          method: api.method,
                          params: params,
                          encoding: api.encoding,
                          headers: api.header)
            .share(replay: 1)
    }
    
    func requestString<S: HTTPType>(_ api: S, params: [String: Any]? = nil) -> Observable<String> {
        var url = api.baseURL
        if let _url = URL(string: api.baseURL.absoluteString + api.path) {
            url = _url
        }
        return self
            ._requestString(url,
                            method: api.method,
                            params: params,
                            encoding: api.encoding,
                            headers: api.header)
            .share(replay: 1)
    }
}
