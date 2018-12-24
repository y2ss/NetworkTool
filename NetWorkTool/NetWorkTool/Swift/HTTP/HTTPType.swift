//
//  HTTPType.swift
//  http
//
//  Created by y2ss on 2018/9/10.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import Foundation
import Alamofire

protocol HTTPType {
    typealias RequestWillBeginBlock = () -> ()
    typealias RequestWillStopBlock = () -> ()
    typealias RequestDidStopBlock = () -> ()
    
    var baseURL: URL { set get }
    var path: String { set get }
    var params: Parameters? { set get }
    var method: HTTPMethod { get }
    var header: HTTPHeaders? { set get }
    var encoding: ParameterEncoding { get }
    var responseType: ResponseType { get }
    var requestTimeout: TimeInterval? { get }
    var responseTimeout: TimeInterval? { get }
    var cachePolicy: HTTPClientBase.CachePolicy? { get }
    var hash: String { get }
    var requestWillBegin: RequestWillBeginBlock? { set get }
    var requestWillStop: RequestWillStopBlock? { set get }
    var requestDidStop: RequestDidStopBlock? { set get }
    /*
     userCache: true 使用缓存策略
     maxAge: 最大缓存时间(s)
     useCacheOnly: true只使用缓存 false使用缓存但是加载后使用加载数据
     */
}

extension HTTPType {
    var baseURL: URL {
        get {
            return URL(string: "http://119.29.40.174")!
        }
        set {}
    }
    
    var path: String {
        get {
            return ""
        }
        set {}
    }
    
    var params: Parameters? {
        get {
            return nil
        }
        set {}
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var header: HTTPHeaders? {
        get {
            return nil
        }
        set {}
    }
    
    var encoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var requestTimeout: TimeInterval? {
        return 60
    }
    
    var responseTimeout: TimeInterval? {
        return 60
    }
    
    var cachePolicy: HTTPClientBase.CachePolicy? {
        return (useCache: false, maxAge: 0, useCacheOnly: false)
    }
    
    var hash: String {
        return (baseURL.absoluteString + path).md5()
    }
    
    var requestWillBegin: RequestWillBeginBlock? {
        get { return nil }
        set {}
    }
    
    var requestWillStop: RequestWillStopBlock? {
        get { return nil }
        set {}
    }
    
    var requestDidStop: RequestDidStopBlock? {
        get { return nil}
        set {}
    }
}

struct HTTPRequest: HTTPType {

}
