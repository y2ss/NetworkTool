//
//  ViewController.swift
//  NetWorkTool
//
//  Created by y2ss on 2018/9/10.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
import Alamofire

class SwiftViewController: UIViewController {
    
    fileprivate var disposeBag = DisposeBag()
    fileprivate var _code = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    @IBAction func onSocketAction(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WSViewController") as! WSViewController
        vc.vctype = .tcp
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func getCaptcha(_ sender: Any) {
        var api = PositionApi()
        api.requestWillStop = {
            print("will stop")
        }
        api.requestWillBegin = {
            print("will begin")
        }
        HTTPClient.shared.request(api)
//        RxHTTP.shared
//            .request(Api.position, params: [:])
//            .do(onSubscribed: {
//                print("subscribed")
//            }, onDispose: {
//                print("dispose")
//            })
//            .subscribe(onNext: { json, string in
//                print(json ?? JSON.null)
//                print(string ?? "nil")
//            }, onError: { error in
//                print(error)
//            }, onCompleted: {
//                print("complete")
//            })
//            .disposed(by: disposeBag)
//
//        HTTPClient.shared
//            .requestBatch([Api.position, Api.test, Api.bodyinfo, Api.checkPatientExist, Api.deviceSetting, PositionApi()],
//                          allReuqestCompleted: { response in
//                            for rep in response {
//
//                                print("\(rep)")
//                            }
//            }) {
//               print("error")
//        }
        
    }
    
    private struct PositionApi: HTTPType {
        private var _requestWillBegin: HTTPType.RequestWillBeginBlock?
        var requestWillBegin: HTTPType.RequestWillBeginBlock? {
            get { return _requestWillBegin }
            set { _requestWillBegin = newValue }
        }
    }

    @IBAction func onDownload(_ sender: Any) {
    
    }

    @IBAction func onIM(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WSViewController") as! WSViewController
        vc.vctype = .websocket
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

enum Api {
    case position
    case test
    case bodyinfo
    case checkPatientExist
    case deviceSetting
    case error
}

extension Api: HTTPType {
    
    var baseURL: URL {
        get {
            return URL(string: "http://localhost:8087")!
        }
        set {}
    }
    
    var method: HTTPMethod {
        switch self {
        case .position, .test, .bodyinfo, .checkPatientExist, .deviceSetting:
            return .get
        default: return .get
        }
    }
    
    var path: String {
        get {
            switch self {
            case .position:
                return "/userinfo/position"
            case .test:
                return "/test"
            case .bodyinfo:
                return "/patient/bodyInfo"
            case .checkPatientExist:
                return "/patient/checkPatientExist"
            case .deviceSetting:
                return "/device/getdevicesetting"
            default:
                return ""
            }
        }
        set {}
    }
    
    
    var params: Parameters? {
        get {
            switch self {
            case .position, .checkPatientExist:
                return ["deviceid": "363d7e17-3e00-4a9c-9cef-bf01286f0def"]
            case .bodyinfo:
                return ["patient_id": "1154528675903928"]
            case .deviceSetting:
                return ["deviceId": "5f51774d-61a4-4e98-b2a1-396c0adbc4fb"]
            default:
                return nil
            }
        }
        set {}
    }
    
    var encoding: ParameterEncoding {
        switch self {
        case .position, .test, .bodyinfo, .checkPatientExist, .deviceSetting:
            return URLEncoding.default
        default:
            return URLEncoding.default
        }
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var cachePolicy: HTTPClientBase.CachePolicy? {
        switch self {
        case .position:
            return (useCache: true, maxAge: 20, useCacheOnly: true)
        default:
            return nil
        }
    }
}



extension String {
    func md5() -> String {
        let str = self.cString(using: .utf8)
        
        let strLen = CUnsignedInt(self.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate()
        return String(format: hash as String)
    }
}
