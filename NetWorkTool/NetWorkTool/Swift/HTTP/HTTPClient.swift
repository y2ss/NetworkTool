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
    
    override func getCommonHeaders() -> [String : String]? {
        if var headers = super.getCommonHeaders() {
            headers["Accept"] = "application/json"
            headers["Content-Type"] = "application/json"
            return headers
        } else {
            return [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ]
        }
    }
    
    private func _url<S: HTTPType>(_ api: S) -> URL {
        var url = api.baseURL
        if let _url = URL(string: api.baseURL.absoluteString + api.path) {
            url = _url
        }
        return url
    }
    
    private func _configuration<S: HTTPType>(_ api: S) {
        if let timeout = api.requestTimeout {
            self.setRequestTimeout(timeout)
        }
        if let timeout = api.responseTimeout {
            self.setResponseTimeout(timeout)
        }
    }
    
    @discardableResult
    func requestJSON<S: HTTPType>(_ api: S, params: [String: Any]? = nil, headers: [String: String]? = nil, success: ((JSON) -> Void)? = nil, failed: ((HTTPError) -> Void)? = nil) -> DataRequest {
        let url = _url(api)
        _configuration(api)
        return self
            ._requestJSON(withBlock: url, method: api.method, params: params, encoding: api.encoding, headers: headers, success: success, failed: failed)
    }
    
    @discardableResult
    func requestString<S: HTTPType>(_ api: S, params: [String: Any]? = nil, headers: [String: String]? = nil, success: ((String) -> Void)? = nil, failed: ((HTTPError) -> Void)? = nil) -> DataRequest {
        let url = _url(api)
        _configuration(api)
        return self
            ._requestString(withBlock: url, method: api.method, params: params, encoding: api.encoding, headers: headers, success: success, failed: failed)
    }

    func upload<S: HTTPType>(_ api: S, fileName: String, data: Data, params: [String: Any]? = nil, headers: [String: String]? = nil, progressChanged:((Double) -> Void)? = nil, success: ((JSON) -> Void)? = nil, failed: ((HTTPError) -> Void)? = nil) {
        let url = self._url(api)
        _configuration(api)
        self.uploadFile(withBlock: url, fileName: fileName, dataOrfileURL: data, method: api.method, headers: headers, params: params, progressChanged: progressChanged, success: success, failed: failed)
    }
    
    
    func upload<S: HTTPType>(_ api: S, fileURL: URL, fileName: String?, params: [String: Any]? = nil, headers: [String: String]? = nil, progressChanged:((Double) -> Void)? = nil, success: ((JSON) -> Void)? = nil, failed: ((HTTPError) -> Void)? = nil) {
        let url = _url(api)
        _configuration(api)
        self.uploadFile(withBlock: url, fileName: fileName, dataOrfileURL: fileURL, method: api.method, headers: headers, params: params, progressChanged: progressChanged, success: success, failed: failed)
    }
}
