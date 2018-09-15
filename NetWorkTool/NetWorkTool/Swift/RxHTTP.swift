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
    
    func requestJSON<S: HTTPType>(_ api: S, params: [String: Any]? = nil, headers: [String: String]? = nil) -> Observable<JSON> {
        let url = self._url(api)
        _configuration(api)
        return self
            ._requestJSON(url,
                          method: api.method,
                          params: params,
                          encoding: api.encoding,
                          headers: headers)
            .share(replay: 1)
    }
    
    func requestString<S: HTTPType>(_ api: S, params: [String: Any]? = nil, headers: [String: String]? = nil) -> Observable<String> {
        let url = self._url(api)
        _configuration(api)
        return self
            ._requestString(url,
                            method: api.method,
                            params: params,
                            encoding: api.encoding,
                            headers: headers)
            .share(replay: 1)
    }
    
    
    func upload<S: HTTPType>(_ api: S, fileName: String, data: Data, params: [String: Any]? = nil, headers: [String: String]? = nil, progressChanged:((Double) -> Void)? = nil) -> Observable<JSON> {
        let url = self._url(api)
        _configuration(api)
        return self
            .uploadFile(url,
                        method: api.method,
                        fileName: fileName,
                        dataOrfileURL: data,
                        params: params,
                        headers: headers,
                        progressChanged: progressChanged)
            .share(replay: 1)
    }
    
    
    func upload<S: HTTPType>(_ api: S, fileURL: URL, fileName: String?, params: [String: Any]? = nil, headers: [String: String]? = nil, progressChanged:((Double) -> Void)? = nil) -> Observable<JSON> {
        let url = self._url(api)
        _configuration(api)
        return self
            .uploadFile(url,
                        method: api.method,
                        fileName: fileName,
                        dataOrfileURL: fileURL,
                        params: params,
                        headers: headers,
                        progressChanged: progressChanged)
            .share(replay: 1)
    }
}
