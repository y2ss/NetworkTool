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
    case setUserInfo
    case getUserInfo
    case uploadAvater
    case test
    case download
    case validateCode
}

extension Api: HTTPType {
    var method: HTTPMethod {
        switch self {
        case .login, .register, .setUserInfo, .uploadAvater:
            return .post
        case .captcha, .getUserInfo, .test, .download, .validateCode:
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
        case .setUserInfo:
            return "/userinfo/setUserinfo"
        case .uploadAvater:
            return "/userinfo/uploadAvater"
        case .getUserInfo:
            return "/userinfo/getUserinfo"
        case .test:
            return "/test"
        case .download:
            return "/upload/video/video1.mp4"
        case .validateCode:
            return "/user/vac"
        }
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .login, .register, .uploadAvater, .setUserInfo:
            return JSONEncoding.default
        case .captcha, .getUserInfo, .test, .download, .validateCode:
            return URLEncoding.default
        }
    }
    
    var requestTimeout: TimeInterval? {
        switch self {
        case .uploadAvater, .download:
            return 600
        default:
            return nil
        }
    }
    
    var responseTimeout: TimeInterval? {
        switch self {
        case .uploadAvater, .download:
            return 600
        default:
            return nil
        }
    }
    
    var header: HTTPHeaders? {//get时header带上token post时body带token
        switch self {
        case .getUserInfo:
            return ["token": UserDefaults.standard.object(forKey: "token") as! String]
        default:
            return nil
        }
    }
}
