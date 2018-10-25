//
//  HTTPError.swift
//  http
//
//  Created by y2ss on 2018/9/10.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

enum HTTPError:Error, LocalizedError {
    case authFailure
    case networkError
    case noConnection
    case notFound
    case parseError
    case serverError(String?, JSON?)
    case timeout
    case cancelled
    case null
    case other(String)
    case errorWithResponse(Error, DataResponse<Any>)
    
    var errorDescription: String? {
        switch self {
        case .authFailure:
            return "请登陆后再试"
        case .networkError:
            return "网络错误"
        case .noConnection:
            return "网络未连接"
        case .notFound:
            return "请求资源不存在"
        case .parseError:
            return "解析服务端数据出错"
        case .serverError(let msg, _):
            if let _msg = msg, !_msg.isEmpty {
                return msg
            } else {
                return "服务器内部错误"
            }
        case .timeout:
            return "请求超时"
        case .cancelled:
            return "请求已取消"
        case .null:
            return "未知错误"
        case .other(let msg):
            return msg
        case .errorWithResponse(let error, let rsp):
            if let rsp_error = rsp.error {
                return rsp_error.localizedDescription
            }
            return error.localizedDescription
        }
    }
}
