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

//        let data = [
//            "code":"13725554033"
//        ]
//        RxHTTP.shared
//            .requestJSON(Api.validateCode, params: data)
//            .subscribe(onNext: { json in
//                print(json)
//            }, onError: { error in
//                print(error)
//            })
//            .disposed(by: disposeBag)
//
    }
    
    @IBAction func getCaptcha(_ sender: Any) {
        code()
    }
    
    @IBAction func onLogin(_ sender: Any) {
        login()
    }
    
    @IBAction func onRegister(_ sender: Any) {
        register()
//        RxHTTP.shared
//            .requestJSON(Api.test)
//            .subscribe(onNext: { json in
//                print(json)
//            }, onError: { error in
//                print(error)
//            })
//        .disposed(by: disposeBag)
    }
    
    @IBAction func onUserinfo(_ sender: UIButton) {
        //setUserinfo("")
        uploadAvater()
    }
    
    @IBAction func onGetUserinfo(_ sender: Any) {
        getUserInfo()
    }
    
 
    @IBAction func onDownload(_ sender: Any) {
        downloadFile()
    }
    
    @IBAction func onIM(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WSViewController")
        self.navigationController?.pushViewController(vc, animated: true)
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
                if let data = json["data"].dictionary {
                    if let token = data["token"]?.string {
                        UserDefaults.standard.set(token, forKey: "token")
                    }
                }
            }, onError: { error in
                print(error)
            }, onDisposed: {
                print("结束请求2")
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func code() {
        let data = [
            "username":"13725554033"
        ]
        RxHTTP.shared
            .requestJSON(Api.captcha, params: data)
            .do(onSubscribe: {
                print("开始请求1")
            }, onDispose: {
                print("结束请求1")
            })
            .subscribe(onNext: { json in
                print(json)
                self._code = json["data"]["code"].intValue
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
        if
            let path = Bundle.main.path(forResource: "ice@2x.png", ofType: nil) {
            let url = URL.init(fileURLWithPath: path)
            do {
                let data = try Data.init(contentsOf: url)
                let param: [String: Any] = [
                    "token":UserDefaults.standard.object(forKey: "token") as! String
                ]
                RxHTTP.shared
                    .upload(Api.uploadAvater, fileName: "imgss", data: data, params: param) { progress in
                        print(progress)
                    }
                    .subscribe(onNext: { json in
                        print(json)
                        if let data = json["data"].dictionary {
                            if let url = data["url"]?.string {
                                self.setUserinfo(url)
                            }
                        }
                    }, onError: { error in
                        print(error)
                    })
                    .disposed(by: disposeBag)
            } catch {
                print(error)
            }
        }
    }
    
    fileprivate func setUserinfo(_ url: String) {
        let data: [String: Any] = [
            "token":UserDefaults.standard.object(forKey: "token") as! String,
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
    
    fileprivate func getUserInfo() {
        let data: [String: Any] = [
            "uid" : "115369211734923996",
        ]
        RxHTTP.shared
            .requestJSON(Api.getUserInfo, params: data)
            .subscribe(onNext: { json in
                print(json)
            }, onError: { error in
                print(error)
            })
            .disposed(by: disposeBag)
    }
    
    fileprivate func downloadFile() {
        RxHTTP.shared
            .download(Api.download,
                      destinationURL: { (url) -> (fileURL: URL?, fileName: String?) in
                        print(url)
                        let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                        let _url = path.appendingPathComponent("ss.mp4", isDirectory: false)
                        return (_url, nil)
            }, progressChanged: { progress in
                print(progress)
            }, success: { (resp, url) in
                print(resp)
            }) { (resp, error) in
                print(error)
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
