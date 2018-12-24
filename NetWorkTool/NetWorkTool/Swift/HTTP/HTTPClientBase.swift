//
//  HTTPClientBase.swift
//  http
//
//  Created by y2ss on 2018/9/9.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import SwiftyJSON
import MobileCoreServices

enum ResponseType {
    case json
    case http
    var description: String {
        switch self {
        case .json:
            return "JSON"
        case .http:
            return "HTTP"
        }
    }
}

protocol HTTPClientConfig {
    var isLogDebug: Bool { get }
    var autoUseCacheWhenNetWorkNotReachable: Bool { get }//当网络连接失败时自动使用缓存
    func log(_ msg: Any)
}

extension HTTPClientConfig {
    var isLogDebug: Bool {
        return true
    }
    
    var autoUseCacheWhenNetWorkNotReachable: Bool {
        return false
    }
    
    func log(_ msg: Any) {
        if isLogDebug {
            print(msg)
        }
    }
}

class HTTPClientBase {
    
    typealias Params = [String: Any]
    typealias CompleteAction = ((JSON?, String?) -> ())
    typealias FailedAction = ((HTTPError) -> ())
    typealias CachePolicy = (useCache: Bool, maxAge: TimeInterval, useCacheOnly: Bool)
    typealias UploadFileConfig = (fileName: String, fileData: Data?, fileURL: URL?)//fileURL或fileData取一个
    typealias DestinationURL = ((_ documentsURL: URL) -> (fileURL: URL?, fileName: String?))
    typealias ProgressChanged = ((Double) -> Void)
    
    fileprivate var session: SessionManager
    fileprivate var cache = YYCache(name: "ss.network.cache")
    fileprivate var config: HTTPClientConfig
    fileprivate var reachabilityManager = NetworkReachabilityManager()
    
    struct DefaultConfig: HTTPClientConfig {}
    
    var isNetworkReachable: Bool {
        return self.networkStatus == .reachable(.ethernetOrWiFi) || self.networkStatus == .reachable(.wwan)
    }
    var networkStatus: Alamofire.NetworkReachabilityManager.NetworkReachabilityStatus = .unknown
    
    func clearCache(_ complete: (() -> ())? = nil) {
        cache?.memoryCache.removeAllObjects()
        cache?.diskCache.removeAllObjects({
            complete?()
        })
    }
    
    init(timeout: TimeInterval = 10, config: HTTPClientConfig = DefaultConfig()) {
        guard type(of: self) != HTTPClientBase.self else {
            fatalError("该类是基类，请继承后使用")
        }
        let cig = URLSessionConfiguration.default
        cig.timeoutIntervalForRequest = timeout
        cig.timeoutIntervalForResource = 30
        let cache = URLCache.shared
        cig.urlCache = cache
        cig.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        session = SessionManager(configuration: cig)
        self.config = config
        
        self.cache?.memoryCache.didReceiveMemoryWarningBlock = { cache in
            self.clearCache()
        }
        reachabilityManager?.listenerQueue = DispatchQueue(label: "com.network.reachability", attributes: .concurrent)
        reachabilityManager?.listener = { status in
            self.networkStatus = status
        }
    }
    
    func setRequestTimeout(_ timeout: TimeInterval) {
        session.session.configuration.timeoutIntervalForRequest = timeout
    }
    
    func setResponseTimeout(_ timeout: TimeInterval) {
        session.session.configuration.timeoutIntervalForResource = timeout
    }
    
    //返回公共头部
    func getCommonHeaders() -> [String: String]? {
        return nil
    }
    
    fileprivate func _getHeaders(_ headers: [String: String]?) -> [String: String] {
        var newHeaders = [String: String]()
        if let commonHeader = self.getCommonHeaders() {
            for (key, value) in commonHeader {
                newHeaders[key] = value
            }
        }
        if let _headers = headers {
            for (key, value) in _headers {
                newHeaders[key] = value
            }
        }
        return newHeaders
    }
    
    private func handleError(_ error: Error, data: Data?) -> HTTPError {
        config.log("error:\(error)")
        if error._code == NSURLErrorTimedOut {
            return HTTPError.timeout
        }
        if error._code == NSURLErrorCancelled {
            return HTTPError.cancelled
        }
        if error._code == NSURLErrorNotConnectedToInternet {
            return HTTPError.noConnection
        }
        if case AFError.responseSerializationFailed(reason: _) = error {
            return HTTPError.parseError
        }
        if
            case let AFError.responseValidationFailed(reason: reason) = error,
            case let AFError.ResponseValidationFailureReason.unacceptableStatusCode(code: statusCode) = reason {
            switch statusCode {
            case 401, 403: return HTTPError.authFailure
            case 404: return HTTPError.notFound
            default:
                if let _data = data, let dataMsg = String(data: _data, encoding: .utf8) {
                    config.log("statusCode:\(statusCode), data:\(dataMsg)")
                    return HTTPError.serverError(dataMsg, nil)
                } else {
                    return HTTPError.serverError("服务端错误", nil)
                }
            }
        }
        return HTTPError.other(error.localizedDescription)
    }
    
    //可以通过override 来对不同api的错误进行不同的逻辑处理
    func handleStringError(_ error: Error, data: Data?) -> HTTPError {
        let httpError = self.handleError(error, data: data)
        guard case HTTPError.serverError(_, _) = httpError else { return httpError }
        return httpError
    }
    
    func handleJSONError(_ error: Error, data: Data?) -> HTTPError {
        let httpError = self.handleError(error, data: data)
        guard case HTTPError.serverError(let msg, _) = httpError else { return httpError }
        guard let _msg = msg else { return HTTPError.null }
        let json = JSON(parseJSON: _msg)
        return HTTPError.serverError(_msg, json)
    }
    
    func handleUploadError(_ error: Error, data: Data?) -> HTTPError {
        let httpError = self.handleError(error, data: data)
        guard case HTTPError.serverError(_, _) = httpError else { return httpError }
        return httpError
    }
    
    func handleDownloadError(_ error: Error, data: Data?) -> HTTPError {
        let httpError = self.handleError(error, data: data)
        guard case HTTPError.serverError(_, _) = httpError else { return httpError }
        return httpError
    }
    
    //MARK: - request
    @discardableResult
    private func _request(
        _ url: URLConvertible,
        method: HTTPMethod,
        params: Parameters?,
        encoding: ParameterEncoding,
        headers: HTTPHeaders?
        ) -> DataRequest {
        let newHeader = self._getHeaders(headers)
        return self.session
            .request(url, method: method, parameters: params, encoding: encoding, headers: newHeader)
            .validate()
    }
    
    func requestREST(_ url: URLConvertible,
                      method: HTTPMethod = .get,
                      params: Parameters? = nil,
                      encoding: ParameterEncoding = JSONEncoding.default,
                      headers: HTTPHeaders? = nil,
                      responseType: ResponseType,
                      cachePolicy: CachePolicy? = nil) -> Observable<(JSON?, String?)> {
        return Observable<(JSON?, String?)>.create({ obs in
            var _cacheKey = ""
            if method == .get {
                _cacheKey = self.cacheKey(url, params)
                if self.cacheHandler(_cacheKey, cachePolicy: cachePolicy, fetchCacheAction: { (json, value) in
                    obs.onNext((json, value))
                }) {
                    obs.onCompleted()
                    return Disposables.create {}
                }
            }
            let request = self._request(url, method: method, params: params, encoding: encoding, headers: headers)
            switch responseType {
            case .http:
                request.responseString(completionHandler: { rsp in
                    self.config.log(rsp)
                    switch rsp.result {
                    case .success(let value):
                        obs.onNext((nil, value))
                        obs.onCompleted()
                        if method == .get {
                            self.cacheData(_cacheKey, cachePolicy: cachePolicy, rsp: rsp.result.value ?? [:])
                        }
                    case .failure(let error):
                        let httpError = self.handleStringError(error, data: rsp.data)
                        self.responseErrorHandler(httpError, method, _cacheKey, cachePolicy,
                                                  timeoutErrorHandler: { (json, value) in
                                                    obs.onNext((json, value))
                        },
                                                  noTimeoutErrorHandler: {
                                                    obs.onError(httpError)
                        })
                    }
                })
            case .json:
                request.responseJSON(completionHandler: { rsp in
                    self.config.log(rsp)
                    switch rsp.result {
                    case .success(let value):
                        let json = JSON(value)//已经判断过json
                        obs.onNext((json, nil))
                        obs.onCompleted()
                        if method == .get {
                            self.cacheData(_cacheKey, cachePolicy: cachePolicy, rsp: rsp.result.value ?? [:])
                        }
                    case .failure(let error):
                        let httpError = self.handleJSONError(error, data: rsp.data)
                        self.responseErrorHandler(httpError, method, _cacheKey, cachePolicy,
                                                  timeoutErrorHandler: { (json, value) in
                                                    obs.onNext((json, value))
                        },
                                                  noTimeoutErrorHandler: {
                                                    obs.onError(httpError)
                        })
                    }
                })
            }
            return Disposables.create {
                request.cancel()
            }
        })
            .observeOn(MainScheduler.instance)
    }
    
    
    func requestREST(withBlock url: URLConvertible,
                     method: HTTPMethod = .get,
                     params: Parameters? = nil,
                     encoding: ParameterEncoding = JSONEncoding.default,
                     headers: HTTPHeaders? = nil,
                     responseType: ResponseType,
                     cachePolicy: CachePolicy? = nil,
                     success: CompleteAction? = nil,
                     failed: FailedAction? = nil,
                     willBegin: HTTPType.RequestWillBeginBlock? = nil,
                     willStop: HTTPType.RequestWillStopBlock? = nil,
                     didStop: HTTPType.RequestDidStopBlock? = nil) -> DataRequest? {
        var _cacheKey = ""
        if method == .get {
            _cacheKey = self.cacheKey(url, params)
            if self.cacheHandler(_cacheKey, cachePolicy: cachePolicy, fetchCacheAction: { (json, value) in
                success?(json, value)
            }) {
                return nil
            }
        }
        willBegin?()
        let dr = self._request(url, method: method, params: params, encoding: encoding, headers: headers)
        switch responseType {
        case .http:
            return dr.responseString(completionHandler: { rsp in
                willStop?()
                self.config.log(rsp)
                switch rsp.result {
                case .success(let value):
                    self.config.log("value:\(value)")
                    success?(nil, value)
                    if method == .get {
                        self.cacheData(_cacheKey, cachePolicy: cachePolicy, rsp: rsp.result.value ?? [:])
                    }
                case .failure(let error):
                    let httpError = self.handleStringError(error, data: rsp.data)
                    self.responseErrorHandler(httpError, method, _cacheKey, cachePolicy,
                                              timeoutErrorHandler: { (json, value) in
                                                success?(json, value)
                    },
                                              noTimeoutErrorHandler: {
                                                failed?(httpError)
                    })
                }
                didStop?()
            })
        case .json:
            return dr.responseJSON(completionHandler: { rsp in
                willStop?()
                self.config.log(rsp)
                switch rsp.result {
                case .success(let value):
                    let json = JSON(value)//已经判断过json
                    success?(json, nil)
                    if method == .get {
                        self.cacheData(_cacheKey, cachePolicy: cachePolicy, rsp: rsp.result.value ?? [:])
                    }
                case .failure(let error):
                    let httpError = self.handleJSONError(error, data: rsp.data)
                    self.responseErrorHandler(httpError, method, _cacheKey, cachePolicy,
                                              timeoutErrorHandler: { (json, value) in
                                                success?(json, value)
                    },
                                              noTimeoutErrorHandler: {
                                                failed?(httpError)
                    })
                }
                didStop?()
            })
        }
    }
    
    private func responseErrorHandler(_ httpError: HTTPError,
                                      _ method: HTTPMethod,
                                      _ cacheKey: String,
                                      _ cachePolicy: CachePolicy?,
                                      timeoutErrorHandler: @escaping (JSON?, String?) -> (),
                                      noTimeoutErrorHandler: @escaping () -> ()) {
        switch httpError {
        case .timeout, .networkError, .noConnection:
            if self.config.autoUseCacheWhenNetWorkNotReachable && method == .get {
                self.cacheHandler(cacheKey, cachePolicy: cachePolicy, fetchCacheAction: { (json, value) in
                    timeoutErrorHandler(json, value)
                })
            } else {
                noTimeoutErrorHandler()
            }
        default:
            noTimeoutErrorHandler()
        }
    }
    
    @discardableResult
    private func cacheHandler(_ cacheKey: String,
                              cachePolicy: CachePolicy?,
                              fetchCacheAction: (JSON?, String?) -> ()) -> Bool {
        if let cachePolicy = cachePolicy, cachePolicy.useCache {
            if let cacheContent = self.cache?.object(forKey: cacheKey) as? NSDictionary {
                if let time = cacheContent["time"] as? TimeInterval {
                    if Date().timeIntervalSince1970 - time < cachePolicy.maxAge {
                        if let data = cacheContent["rsp"] {
                            fetchCacheAction(JSON(data), data as? String)
                            if cachePolicy.useCacheOnly {
                                return true
                            }
                        }
                    } else {
                        self.config.log("cache expire, start request")
                        self.cache?.removeObject(forKey: cacheKey)
                    }
                }
            }
        }
        return false
    }
    
    private func cacheData(_ cacheKey: String, cachePolicy: CachePolicy?, rsp: Any) {
        if let cachePolicy = cachePolicy, cachePolicy.useCache {
            let cacheContent = [
                "rsp": rsp,
                "time": Date().timeIntervalSince1970
                ] as [String : AnyObject]
            self.cache?.setObject(NSDictionary(dictionary: cacheContent), forKey: cacheKey)
        }
    }
    
    
    private var cacheKey: (URLConvertible, Parameters?) -> (String) {
        return { url, params in
            if let _url = try? url.asURL() {
                var cachekey = _url.absoluteString
                if let params = params {
                    for (key, value) in params {
                        cachekey += "\(key):\(value);"
                    }
                }
                return cachekey.md5()
            }
            return "\(Date())".md5()
        }
    }
}



//MARK: - upload
extension HTTPClientBase {
    func uploadFile(
        _ url: URLConvertible,
        method: HTTPMethod,
        multipartFormData: @escaping ((MultipartFormData) -> Void),
        headers: HTTPHeaders?,
        progressChanged: ProgressChanged?
        ) -> Observable<JSON> {
        return Observable<JSON>.create({ obs in
            let newHeaders: [String: String] = self._getHeaders(headers)
            var request: Request?
            self.session
                .upload(multipartFormData: multipartFormData,
                        to: url,
                        method: method,
                        headers: newHeaders,
                        encodingCompletion: { encodingResult in
                            self.config.log(encodingResult)
                            switch encodingResult {
                            case .success(let upload, _, _):
                                request = upload.uploadProgress(closure: {
                                    progressChanged?($0.fractionCompleted)
                                })
                                    .validate()
                                    .responseJSON(completionHandler: { rsp in
                                        self.config.log(rsp)
                                        switch rsp.result {
                                        case .success(let value):
                                            let json = JSON(value)
                                            obs.onNext(json)
                                            obs.onCompleted()
                                            break
                                        case .failure(let error):
                                            let httpError = self.handleUploadError(error, data: rsp.data)
                                            obs.onError(httpError)
                                            break
                                        }
                                    })
                            case .failure(let encodingError):
                                obs.onError(HTTPError.other(encodingError.localizedDescription))
                            }
                })
            return Disposables.create {
                request?.cancel()
            }
        })
        .observeOn(MainScheduler.instance)
    }
    
    func uploadFile(
        _ url: URLConvertible,
        method: HTTPMethod,
        fileName: String?,
        dataOrfileURL: Any?,
        params: Parameters?,
        headers: HTTPHeaders?,
        progressChanged:ProgressChanged?
        ) -> Observable<JSON> {
        return self
            .uploadFile(url,
                        method: method,
                        multipartFormData: { multipartFormData in
                            if let params = params {
                                for (key, value) in params {
                                    if let _value = value as? String, let stringData = _value.data(using: String.Encoding.utf8) {
                                        multipartFormData.append(stringData, withName: key)
                                    }
                                }
                            }
                            //把文件放在最后面，这样兼容性最好
                            if let data = dataOrfileURL as? Data {
                                multipartFormData.append(data,
                                                         withName: "file",
                                                         fileName: fileName ?? "file_\(Date())",
                                    mimeType: data.mimeType)
                            }
                            if let url = dataOrfileURL as? URL {
                                if let fileName = fileName {
                                    let mime = url.pathExtension.mimeType
                                    multipartFormData.append(url, withName: "file", fileName: fileName, mimeType: mime)
                                } else {
                                    multipartFormData.append(url, withName: "file")
                                }
                            }
            },
                        headers: headers,
                        progressChanged: progressChanged)
    }
    
    func uploadFile(withBlock
        url: URLConvertible,
        method: HTTPMethod,
        multipartFormData: @escaping ((MultipartFormData)->Void),
        headers: HTTPHeaders?,
        progressChanged: ProgressChanged?,
        success:((JSON)->Void)?,
        failed: ((HTTPError)->Void)?
        ) {
        let newHeaders:[String:String] = self._getHeaders(headers)
        return self.session
            .upload(multipartFormData: multipartFormData,
                    to: url,
                    method: method,
                    headers: newHeaders,
                    encodingCompletion: { encodingCompletion in
                        self.config.log(encodingCompletion)
                        switch encodingCompletion {
                        case .success(let request, _, _):
                            request.uploadProgress(closure: {
                                progressChanged?($0.fractionCompleted)
                            })
                                .validate()
                                .responseJSON(completionHandler: { rsp in
                                    self.config.log(rsp)
                                    switch rsp.result {
                                    case .success(let value):
                                        let json = JSON(value)
                                        success?(json)
                                        break
                                    case .failure(let error):
                                        let httpError = self.handleUploadError(error, data: rsp.data)
                                        failed?(httpError)
                                        break
                                    }
                                })
                            break
                        case .failure(let encodingError):
                            failed?(HTTPError.other(encodingError.localizedDescription))
                            break
                        }
            })
    }
    
    func uploadFile(withBlock
        url: URLConvertible,
        fileName: String?,
        dataOrfileURL: Any?,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        params: Parameters?,
        progressChanged: ProgressChanged?,
        success:((JSON)->Void)?,
        failed: ((HTTPError)->Void)?
        ) {
        self.uploadFile(withBlock: url,
                        method: method,
                        multipartFormData: { multipartFormData in
                            if let params = params {
                                for (key, value) in params {
                                    if let _value = value as? String, let stringData = _value.data(using: String.Encoding.utf8) {
                                        multipartFormData.append(stringData, withName: key)
                                    }
                                }
                            }
                            //把文件放在最后面，这样兼容性最好
                            if let data = dataOrfileURL as? Data {
                                multipartFormData.append(data,
                                                         withName: "file",
                                                         fileName: fileName ?? "file_\(Date())",
                                    mimeType: data.mimeType)
                            }
                            if let url = dataOrfileURL as? URL {
                                if let fileName = fileName {
                                    let mime = url.pathExtension.mimeType
                                    multipartFormData.append(url, withName: "file", fileName: fileName, mimeType: mime)
                                } else {
                                    multipartFormData.append(url, withName: "file")
                                }
                            }
        },
                        headers: headers,
                        progressChanged: progressChanged,
                        success: success,
                        failed: failed)
    }
}

//MARK: - download
extension HTTPClientBase {
    private var fileURL: (HTTPURLResponse, DestinationURL?, String?) -> (URL) {
        return { response, destinationURL, fileName in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            var fileURL: URL = documentsURL.appendingPathComponent(response.suggestedFilename ?? "\(Date())", isDirectory: false)
            if let dURL = destinationURL?(documentsURL) {
                if let _ = dURL.fileURL {
                    fileURL = dURL.fileURL!
                } else {
                    fileURL = documentsURL.appendingPathComponent(fileName ?? response.suggestedFilename!, isDirectory: false)
                }
            }
            return fileURL
        }
    }
    
    func downloadFile(_ url: URLConvertible,
                      destinationURL: DestinationURL?,
                      fileName: String?,
                      method: HTTPMethod,
                      headers: HTTPHeaders?,
                      params: Parameters?,
                      encoding: ParameterEncoding,
                      progressChanged: ProgressChanged?)
        -> Observable<(DownloadResponse<Data>, Data?, URL?, HTTPError?)> {
            let newHeaders = self._getHeaders(headers)
            let destination: DownloadRequest.DownloadFileDestination = { _, response in
                return (self.fileURL(response, destinationURL, fileName), [.removePreviousFile, .createIntermediateDirectories])
            }
            return Observable<(DownloadResponse<Data>, Data?, URL?, HTTPError?)>.create({ obs in
                let req = self.session
                    .download(url,
                              method: method,
                              parameters: params,
                              encoding: encoding,
                              headers: newHeaders,
                              to: destination)
                    .validate()
                    .responseData(completionHandler: { rsp in
                        self.config.log(rsp)
                        switch rsp.result {
                        case .success(let value):
                            obs.onNext((rsp, value, rsp.destinationURL, nil))
                            obs.onCompleted()
                        case .failure(let error):
                            obs.onError(HTTPError.other(error.localizedDescription))
                        }
                    })
                return Disposables.create {
                    req.cancel()
                }
            })
    }
    
    func downloadFile(
        withBlock url: URLConvertible,
        destinationURL: DestinationURL?,
        fileName: String?,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        params: Parameters?,
        encoding: ParameterEncoding,
        progressChanged: ProgressChanged?,
        success:((DownloadResponse<Data>, URL?)->Void)?,
        failed:((DownloadResponse<Data>, HTTPError)->Void)?
        ) -> DownloadRequest {
        let newHeaders = self._getHeaders(headers)
        let destination: DownloadRequest.DownloadFileDestination = { _, response in
            return (self.fileURL(response, destinationURL, fileName), [.removePreviousFile, .createIntermediateDirectories])
        }
        return session
            .download(url,
                      method: method,
                      parameters: params,
                      encoding: encoding,
                      headers: newHeaders,
                      to: destination)
            .downloadProgress(closure: { progress in
                progressChanged?(progress.fractionCompleted)
            })
            .responseData(completionHandler: { rsp in
                self.config.log(rsp)
                switch rsp.result {
                case .success(_):
                    success?(rsp, rsp.destinationURL)
                    break
                case .failure(let error):
                    let httpError = self.handleDownloadError(error, data: rsp.resumeData)
                    failed?(rsp, httpError)
                    break
                }
            })
    }
}

public extension Data {
    private static let mimeTypeSignatures: [UInt8 : String] = [
        0xFF : "image/jpeg",
        0x89 : "image/png",
        0x47 : "image/gif",
        0x49 : "image/tiff",
        0x4D : "image/tiff",
        0x25 : "application/pdf",
        0xD0 : "application/vnd",
        0x46 : "text/plain",
        ]
    
    var mimeType: String {
        var c: UInt8 = 0
        copyBytes(to: &c, count: 1)
        return Data.mimeTypeSignatures[c] ?? "application/octet-stream"
    }
}

public extension String {
    var mimeType: String {
        if
            let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue()
        {
            return contentType as String
        }
        
        return "application/octet-stream"
    }
}
