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
    
    class var shared: RxHTTP { return _instance }
    
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
    
    private init(timeout: TimeInterval) {
        super.init(timeout: timeout)
    }
    
    private var configuration: (HTTPType, HTTPHeaders?, Params?) -> (url: URL, header: HTTPHeaders, params: Params?) {
        return { api, header, params in
            var url = api.baseURL
            if let _url = URL(string: api.baseURL.absoluteString + api.path) {
                url = _url
            }
            var _header = [String: String]()
            if let headers = header {
                for (key, value) in headers {
                    _header[key] = value
                }
            }
            if let apiHeaders = api.header {
                for (key, value) in apiHeaders {
                    _header[key] = value
                }
            }
            var _params = [String: Any]()
            if let params = params {
                for (key, value) in params {
                    _params[key] = value
                }
            }
            if let apiParams = api.params {
                for (key, value) in apiParams {
                    _params[key] = value
                }
            }
            return (url, _header, _params)
        }
    }
    
    func request(_ api: HTTPType,
                 params: Params? = nil,
                 headers: HTTPHeaders? = nil)
        -> Observable<(JSON?, String?)> {
            let config = configuration(api, headers, params)
            return requestREST(config.url,
                               method: api.method,
                               params: config.params,
                               encoding: api.encoding,
                               headers: config.header,
                               responseType: api.responseType,
                               cachePolicy: api.cachePolicy)
    }
    
    func upload(_ api: HTTPType,
                fileConfig: UploadFileConfig,
                params: Params? = nil,
                headers: HTTPHeaders? = nil,
                progressChanged: ProgressChanged? = nil)
        -> Observable<JSON> {
            let config = configuration(api, headers, params)
            return self
                .uploadFile(config.url,
                            method: api.method,
                            fileName: fileConfig.fileName,
                            dataOrfileURL: fileConfig.fileURL == nil ? fileConfig.fileData : fileConfig.fileURL,
                            params: config.params,
                            headers: config.header,
                            progressChanged: progressChanged)
                .share(replay: 1, scope: .whileConnected)
    }
    
    func download(_ api: HTTPType,
                  fileName: String? = nil,
                  destinationURL: DestinationURL? = nil,
                  params: Params,
                  headers: HTTPHeaders? = nil,
                  progressChanged: ProgressChanged? = nil)
        -> Observable<(DownloadResponse<Data>, Data?, URL?, HTTPError?)> {
            let config = configuration(api, headers, params)
            return self
                .downloadFile(config.url,
                              destinationURL: destinationURL,
                              fileName: fileName,
                              method: api.method,
                              headers: config.header,
                              params: config.params,
                              encoding: api.encoding,
                              progressChanged: progressChanged)
                .share()
    }
    
 
}


