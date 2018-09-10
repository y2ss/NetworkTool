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

class HTTPClientBase {
    
    private var session: SessionManager
    
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
    
    //返回公共头部
    func getCommonHeaders() -> [String: String]? {
        return nil
    }
    
    @discardableResult
    private func _request(
        _ url: URLConvertible,
        method: HTTPMethod,
        params: Parameters?,
        encoding: ParameterEncoding,
        headers: HTTPHeaders?
        ) -> DataRequest {
        var newHeader = [String: String]()
        if let commonHeader = self.getCommonHeaders() {
            for (key, value) in commonHeader {
                newHeader[key] = value
            }
        }
        if let _headers = headers {
            for (key, value) in _headers {
                newHeader[key] = value
            }
        }
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
                    return HTTPError.serverError(nil, nil)
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
    
}
