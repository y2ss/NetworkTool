//
//  HTTPType.swift
//  http
//
//  Created by y2ss on 2018/9/10.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import Foundation
import Alamofire

enum Api {
    case login
    case captcha
    case register
}

extension Api: HTTPType {
    var method: HTTPMethod {
        switch self {
        case .login, .register:
            return .post
        case .captcha:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .login:
            return "/user/login"
        case .captcha:
            return "/user/code"
        case .register:
            return "/user/register"
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .login, .register:
            return JSONEncoding.default
        case .captcha:
            return URLEncoding.default
        }
    }
}
