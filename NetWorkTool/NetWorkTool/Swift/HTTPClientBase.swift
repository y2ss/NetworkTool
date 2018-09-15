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

class HTTPClientBase {
    
    fileprivate var session: SessionManager
    
    init(timeout:TimeInterval = 10) {
        guard type(of: self) != HTTPClientBase.self else {
            fatalError("该类是基类，请继承后使用")
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = 30
        let cache = URLCache.shared
        config.urlCache = cache
        config.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        
        session = SessionManager(configuration: config)
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
        print("error:\(error)")
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
                    print("statusCode:\(statusCode), data:\(dataMsg)")
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
        guard case HTTPError.serverError(_, _) = httpError else {
            return httpError
        }
        
        //这里可以对错误做进一步处理
        return httpError
    }
    
    func handleJSONError(_ error: Error, data: Data?) -> HTTPError {
        let httpError = self.handleError(error, data: data)
        guard case HTTPError.serverError(let msg, _) = httpError else {
            return httpError
        }
        guard let _msg = msg else {
            return HTTPError.null
        }
        
        let json = JSON(parseJSON: _msg)
        return HTTPError.serverError(_msg, json)
    }
    
    func handleUploadError(_ error: Error, data: Data?) -> HTTPError {
        let httpError = self.handleError(error, data: data)
        
        guard case HTTPError.serverError(_, _) = httpError else {
            return httpError
        }
        //do something on business
        
        return httpError
    }
    
    func handleDownloadError(_ error: Error, data: Data?) -> HTTPError {
        let httpError = self.handleError(error, data: data)
        
        guard case HTTPError.serverError(_, _) = httpError else {
            return httpError
        }
        
        return httpError
    }
}

//MARK: - request
extension HTTPClientBase {
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
    
    func _requestString(
        _ url: URLConvertible,
        method: HTTPMethod,
        params: Parameters?,
        encoding: ParameterEncoding,
        headers: HTTPHeaders?
        ) -> Observable<String> {
        return Observable<String>.create({ obs in
            let request = self
                ._request(url, method: method, params: params, encoding: encoding, headers: headers)
                .responseString(completionHandler: { rsp in
                    switch rsp.result {
                    case .success(let value):
                        print("value:\(value)")
                        obs.onNext(value)
                        obs.onCompleted()
                        break
                    case .failure(let error):
                        print("error:\(error)")
                        let httpError = self.handleStringError(error, data: rsp.data)
                        obs.onError(httpError)
                        break
                    }
                })
            return Disposables.create {
                request.cancel()
            }
        })
            .observeOn(MainScheduler.instance)
    }
    
    func _requestJSON(
        _ url: URLConvertible,
        method: HTTPMethod,
        params: Parameters?,
        encoding: ParameterEncoding,
        headers: HTTPHeaders?
        ) -> Observable<JSON> {
        return Observable<JSON>.create({ obs in
            let request = self
                ._request(url, method: method, params: params, encoding: encoding, headers: headers)
                .responseJSON(completionHandler: { rsp in
                    switch rsp.result {
                    case .success(let value):
                        let json = JSON(value)//已经判断过json
                        print("JSON:\(json)")
                        obs.onNext(json)
                        obs.onCompleted()
                        break
                    case .failure(let error):
                        let httpError = self.handleJSONError(error, data: rsp.data)
                        obs.onError(httpError)
                        break
                    }
                })
            return Disposables.create {
                request.cancel()
            }
        })
            .observeOn(MainScheduler.instance)
    }
    
    
    func _requestJSON(withBlock
        url: URLConvertible,
                      method: HTTPMethod,
                      params: Parameters?,
                      encoding: ParameterEncoding,
                      headers: HTTPHeaders?,
                      success: ((JSON) -> Void)?,
                      failed: ((HTTPError) -> Void)?) -> DataRequest {
        return self
            ._request(url, method: method, params: params, encoding: encoding, headers: headers)
            .responseJSON(completionHandler: { rsp in
                switch rsp.result {
                case .success(let value):
                    let json = JSON(value)
                    print("JSON:\(json)")
                    success?(json)
                    break
                case .failure(let error):
                    let httpError = self.handleJSONError(error, data: rsp.data)
                    failed?(httpError)
                    break
                }
            })
    }
    
    func _requestString(withBlock
        url: URLConvertible,
                        method: HTTPMethod,
                        params: Parameters?,
                        encoding: ParameterEncoding,
                        headers: HTTPHeaders?,
                        success: ((String) -> Void)?,
                        failed: ((HTTPError) -> Void)?) -> DataRequest {
        return self
            ._request(url, method: method, params: params, encoding: encoding, headers: headers)
            .responseString(completionHandler: { rsp in
                switch rsp.result {
                case .success(let value):
                    print("value:\(value)")
                    success?(value)
                    break
                case .failure(let error):
                    let httpError = self.handleJSONError(error, data: rsp.data)
                    failed?(httpError)
                    break
                }
            })
    }
}

//MARK: - upload
extension HTTPClientBase {
    private func uploadFile(
        _ url: URLConvertible,
        method: HTTPMethod,
        multipartFormData: @escaping ((MultipartFormData) -> Void),
        headers: HTTPHeaders?,
        progressChanged: ((Double) -> Void)?
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
                            switch encodingResult {
                            case .success(let upload, _, _):
                                request = upload.uploadProgress(closure: {
                                    progressChanged?($0.fractionCompleted)
                                })
                                    .validate()
                                    .responseJSON(completionHandler: { rsp in
                                        switch rsp.result {
                                        case .success(let value):
                                            let json = JSON(value)
                                            print("json:\(json)")
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
        dataOrfileURL: Any,
        params: Parameters?,
        headers: HTTPHeaders?,
        progressChanged:((Double) -> Void)?
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
    
    private func uploadFile(withBlock
        url: URLConvertible,
        method: HTTPMethod,
        multipartFormData: @escaping ((MultipartFormData)->Void),
        headers: HTTPHeaders?,
        progressChanged: ((Double)->Void)?,
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
                        switch encodingCompletion {
                        case .success(let request, _, _):
                            request.uploadProgress(closure: {
                                progressChanged?($0.fractionCompleted)
                            })
                                .validate()
                                .responseJSON(completionHandler: { rsp in
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
        dataOrfileURL: Any,
        method: HTTPMethod,
        headers: HTTPHeaders?,
        params: Parameters?,
        progressChanged: ((Double)->Void)?,
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
