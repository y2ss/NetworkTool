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
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var encoding: ParameterEncoding { get }
    var header: [String: String]? { get }
}

extension HTTPType {
    var baseURL: URL {
        return URL(string: "http://119.29.139.84")!
    }
    
    var path: String {
        return ""
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
    
    var header: [String: String]? {
        return nil
    }
}
