//
//  IMViewController.swift
//  NetWorkTool
//
//  Created by y2ss on 2018/9/21.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import UIKit

class WSViewController: UIViewController, WebSocketMgrDelegate {

    @IBOutlet weak var textView2: UITextView!
    @IBOutlet weak var textView1: UITextView!
    
    var strs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        WebSocketMgr.shared.delegate = self
    }
    
    @IBAction func onSend(_ sender: UIButton) {
        WebSocketMgr.shared.sendMsg(textView1.text)
    }
    
    @IBAction func onConnect(_ sender: UIButton) {
        WebSocketMgr.shared.connect("ws://119.29.40.174:8083/ws")
    }
    
    @IBAction func onDisConnect(_ sender: Any) {
        WebSocketMgr.shared.close()
    }
    
    func webSocketDidReceiveMessage(_ msg: Any) {
        strs.append(msg as! String)
        strs.append("\n")
        
        var text = ""
        for str in strs {
            text.append(str)
        }
        textView2.text = text
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView1.resignFirstResponder()
    }
}
