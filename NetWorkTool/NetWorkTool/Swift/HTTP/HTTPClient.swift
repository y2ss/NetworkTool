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
    class var shared: HTTPClient { return _instance }
    
    private init(timeout: TimeInterval) {
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
    
    @discardableResult
    func request(_ api: HTTPType,
                 params: Params? = nil,
                 headers: HTTPHeaders? = nil,
                 success: CompleteAction? = nil,
                 failed: FailedAction? = nil) -> DataRequest? {
        let config = configuration(api, headers, params)
        return requestREST(withBlock: config.url,
                           method: api.method,
                           params: config.params,
                           encoding: api.encoding,
                           headers: config.header,
                           responseType: api.responseType,
                           cachePolicy: api.cachePolicy,
                           success: success,
                           failed: failed,
                           willBegin: api.requestWillBegin,
                           willStop: api.requestWillStop,
                           didStop: api.requestDidStop)
    }
    
    func upload(_ api: HTTPType,
                fileConfig: UploadFileConfig,
                params: Params? = nil,
                headers: HTTPHeaders? = nil,
                progressChanged:ProgressChanged? = nil,
                success: ((JSON) -> Void)? = nil,
                failed: FailedAction? = nil) {
        let config = configuration(api, headers, params)
        self.uploadFile(withBlock: config.url,
                        fileName: fileConfig.fileName,
                        dataOrfileURL: fileConfig.fileURL == nil ? fileConfig.fileData : fileConfig.fileURL,
                        method: api.method,
                        headers: config.header,
                        params: config.params,
                        progressChanged: progressChanged,
                        success: success,
                        failed: failed)
    }
    
    @discardableResult
    func download(_ api: HTTPType,
                  fileName: String? = nil,
                  destinationURL: DestinationURL? = nil,
                  params: Params? = nil,
                  headers: HTTPHeaders? = nil,
                  progressChanged: ProgressChanged? = nil,
                  success: ((DownloadResponse<Data>, URL?) -> Void)? = nil,
                  failed: ((DownloadResponse<Data>, HTTPError) -> Void)? = nil) -> DownloadRequest {
        let config = configuration(api, headers, params)
        return self.downloadFile(withBlock: config.url,
                                 destinationURL: destinationURL,
                                 fileName: fileName,
                                 method: api.method,
                                 headers: config.header,
                                 params: config.params,
                                 encoding: api.encoding,
                                 progressChanged: progressChanged,
                                 success: success,
                                 failed: failed)
    }
    
    
    func requestBatch(_ apis: [HTTPType],
                      cancelAllReuqestWhenOnceFailed: Bool = true,
                      allReuqestCompleted: (([(DataRequest?, HTTPType, JSON?, String?)]) -> ())? = nil,
                      failed: (() -> ())? = nil) {
        let group = DispatchGroup()
        var dataReqs = [(DataRequest?, HTTPType, JSON?, String?)]()
        var success = true
        for api in apis {
            group.enter()
            let req = self.request(api, success: { json, value in
                group.leave()
                for (index, req) in dataReqs.enumerated() {
                    if req.1.hash == api.hash {
                        dataReqs[index].2 = json
                        dataReqs[index].3 = value
                    }
                }
            }) { error in
                group.leave()
                if cancelAllReuqestWhenOnceFailed {
                    for req in dataReqs {
                        req.0?.cancel()
                    }
                }
                success = false
            }
            dataReqs.append((req, api, nil, nil))
        }
        group.notify(queue: DispatchQueue.main) {
            if success {
                allReuqestCompleted?(dataReqs)
            } else {
                failed?()
            }
        }
    }
}

