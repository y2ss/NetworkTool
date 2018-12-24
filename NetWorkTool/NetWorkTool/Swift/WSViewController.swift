//
//  IMViewController.swift
//  NetWorkTool
//
//  Created by y2ss on 2018/9/21.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import UIKit

class WSViewController: UIViewController, WebSocketMgrDelegate {
    
    enum VCType {
        case websocket
        case tcp
    }
    
    var vctype: VCType = .websocket

    @IBOutlet weak var textView2: UITextView!
    @IBOutlet weak var textView1: UITextView!
    
    var strs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if vctype == .websocket {
            WebSocketMgr.shared.delegate = self
        } else if vctype == .tcp {
            
        }
    }
    
    @IBAction func onSend(_ sender: UIButton) {
        if vctype == .websocket {
            WebSocketMgr.shared.sendMsg(textView1.text)
        } else if vctype == .tcp {
            SocketMgr.shared.sendMsg(textView1.text)
        }
        
    }
    
    @IBAction func onConnect(_ sender: UIButton) {
        if vctype == .websocket {
            WebSocketMgr.shared.connect("ws://localhost:8083/ws")
        } else if vctype == .tcp {
            SocketMgr.shared.connect()
        }
        
    }
    
    @IBAction func onDisConnect(_ sender: Any) {
        if vctype == .websocket {
            WebSocketMgr.shared.close()
        } else if vctype == .tcp {
            SocketMgr.shared.disconnect()
        }
        
       
    }
    
    func webSocketDidReceiveMessage(_ msg: Any) {
        if vctype == .websocket {
            strs.append(msg as! String)
            strs.append("\n")
            
            var text = ""
            for str in strs {
                text.append(str)
            }
            textView2.text = text
        } else if vctype == .tcp {
            
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView1.resignFirstResponder()
    }
}
