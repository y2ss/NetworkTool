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
    
    private func _headers<S: HTTPType>(_ api: S, headers: HTTPHeaders?) -> HTTPHeaders? {
        if var api_header = api.header, let header = headers {
            api_header += header
            return api_header
        } else {
            if let _ = api.header {
                return api.header
            }
            if let _ = headers {
                return headers
            }
            return nil
        }
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
        _configuration(api)
        return self
            ._requestJSON(_url(api),
                          method: api.method,
                          params: params,
                          encoding: api.encoding,
                          headers: _headers(api, headers: headers))
            .share(replay: 1)
    }
    
    func requestString<S: HTTPType>(_ api: S, params: [String: Any]? = nil, headers: [String: String]? = nil) -> Observable<String> {
        _configuration(api)
        return self
            ._requestString(_url(api),
                            method: api.method,
                            params: params,
                            encoding: api.encoding,
                            headers: _headers(api, headers: headers))
            .share(replay: 1)
    }
    
    
    func upload<S: HTTPType>(_ api: S, fileName: String, data: Data, params: [String: Any]? = nil, headers: [String: String]? = nil, progressChanged:((Double) -> Void)? = nil) -> Observable<JSON> {
        _configuration(api)
        return self
            .uploadFile(_url(api),
                        method: api.method,
                        fileName: fileName,
                        dataOrfileURL: data,
                        params: params,
                        headers: _headers(api, headers: headers),
                        progressChanged: progressChanged)
            .share(replay: 1)
    }
    
    
    func upload<S: HTTPType>(_ api: S, fileURL: URL, fileName: String?, params: [String: Any]? = nil, headers: [String: String]? = nil, progressChanged:((Double) -> Void)? = nil) -> Observable<JSON> {
        _configuration(api)
        return self
            .uploadFile(_url(api),
                        method: api.method,
                        fileName: fileName,
                        dataOrfileURL: fileURL,
                        params: params,
                        headers: _headers(api, headers: headers),
                        progressChanged: progressChanged)
            .share(replay: 1)
    }
    
    @discardableResult
    func download<S: HTTPType>(_ api: S, fileName: String? = nil, destinationURL: DestinationURL? = nil, params: [String: Any]? = nil, headers: [String: String]? = nil, progressChanged: ((Double) -> Void)? = nil, success:((DownloadResponse<Data>, URL?)->Void)? = nil, failed:((DownloadResponse<Data>, HTTPError)->Void)? = nil) -> DownloadRequest {
        return self
            .downloadFile(_url(api), destinationURL: destinationURL, fileName: fileName, method: api.method, headers: _headers(api, headers: headers), params: params, encoding: api.encoding, progressChanged: progressChanged, success: success, failed: failed)
    }
    
}

func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}
