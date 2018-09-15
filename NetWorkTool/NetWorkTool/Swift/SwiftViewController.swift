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

class SwiftViewController: UIViewController {
    
    fileprivate var disposeBag = DisposeBag()
    fileprivate var _code = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func getCaptcha(_ sender: Any) {
        code()
    }
    
    @IBAction func onLogin(_ sender: Any) {
        login()
    }
    
    @IBAction func onRegister(_ sender: Any) {
        register()
    }
    
    @IBAction func onUserinfo(_ sender: UIButton) {
        //setUserinfo("")
        uploadAvater()
    }
    
}

extension SwiftViewController {
    fileprivate func login() {
        let data = [
            "username":"13725554033",
            "password":"123456".md5(),
            "code":"\(_code)"
        ]
        RxHTTP.shared
            .requestJSON(Api.login, params: data)
            .do(onSubscribe: {
                print("开始请求2")
            })
            .subscribe(onNext: { json in
                print(json)
            }, onError: { error in
                print(error)
            }, onDisposed: {
                print("结束请求2")
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func code() {
        RxHTTP.shared
            .requestJSON(Api.captcha)
            .do(onSubscribe: {
                print("开始请求1")
            }, onDispose: {
                print("结束请求1")
            })
            .subscribe(onNext: { json in
                self._code = json["data"].intValue
            }, onError: { error in
                print(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func register() {
        let data = [
            "username":"13725554033",
            "password":"123456".md5()
        ]
        HTTPClient.shared
            .requestJSON(Api.register,
                         params: data,
                         success: { json in
                     print(json)
            }) { error in
                print(error)
        }
    }
    
    fileprivate func uploadAvater() {
        if let data = UIImagePNGRepresentation(UIImage(named: "ice@2x.png")!) {
            RxHTTP.shared
                .upload(Api.uploadAvater, fileName: "ss", data: data) { progress in
                    print(progress)
                }
                .subscribe(onNext: { json in
                    if let data = json["data"].dictionary {
                        if let url = data["url"]?.string {
                            self.setUserinfo(url)
                        }
                    }
                }, onError: { error in
                    print(error)
                })
                .disposed(by: disposeBag)
        }
    }
    
    fileprivate func setUserinfo(_ url: String) {
        let data: [String: Any] = [
            "uid":"115369211734923996",
            "gender":2,
            "nickname":"珊珊",
            "url":url
        ]
        RxHTTP.shared
            .requestJSON(Api.setUserInfo, params: data)
            .subscribe(onNext: { json in
                print(json)
            }, onError: { error in
                print(error)
            })
            .disposed(by: disposeBag)
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
