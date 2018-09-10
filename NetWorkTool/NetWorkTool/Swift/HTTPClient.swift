//
//  HTTPClient.swift
//  http
//
//  Created by y2ss on 2018/9/10.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class HTTPClient: HTTPClientBase {
    
    private static var _instance = HTTPClient(timeout: 20)
    
    class var shared: HTTPClient {
        return _instance
    }
    
    private override init(timeout: TimeInterval) {
        super.init(timeout: timeout)
    }
    
    @discardableResult
    func requestJSON<S: HTTPType>(_ api: S, params: [String: Any]? = nil, success: ((JSON) -> Void)? = nil, failed: ((HTTPError) -> Void)? = nil) -> DataRequest {
        var url = api.baseURL
        if let _url = URL(string: api.baseURL.absoluteString + api.path) {
            url = _url
        }
        return self
            ._requestJSON(withBlock: url, method: api.method, params: params, encoding: api.encoding, headers: api.header, success: success, failed: failed)
    }
    
    @discardableResult
    func requestString<S: HTTPType>(_ api: S, params: [String: Any]? = nil, success: ((String) -> Void)? = nil, failed: ((HTTPError) -> Void)? = nil) -> DataRequest {
        var url = api.baseURL
        if let _url = URL(string: api.baseURL.absoluteString + api.path) {
            url = _url
        }
        return self
            ._requestString(withBlock: url, method: api.method, params: params, encoding: api.encoding, headers: api.header, success: success, failed: failed)
    }
    
}
