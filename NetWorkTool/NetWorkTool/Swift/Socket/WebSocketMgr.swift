//
//  WebSocketMgr.swift
//  NetWorkTool
//
//  Created by y2ss on 2018/10/10.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import Foundation

protocol WebSocketMgrDelegate: class {
    func webSocketDidReceiveMessage(_ msg: Any)
}

class WebSocketMgr: NSObject {
    
    static private var __instance = WebSocketMgr()
    
    weak var delegate: WebSocketMgrDelegate?
    
    class var shared: WebSocketMgr {
        return __instance
    }
    
    fileprivate var socket: SRWebSocket? = nil
    
    private var heartbeat_timer: Timer?
    private var websocketURL = ""
    
    private override init() {
        
    }
    
    @discardableResult
    public func connect(_ url: String) -> Bool {
        if let _ = socket { return true }
        guard let _url = URL(string: url) else {
            print("websocket url error")
            return false
        }
        websocketURL = url
        socket = SRWebSocket(urlRequest: URLRequest(url: _url))
        socket!.delegate = self
        socket!.open()
        
        return true
    }
    
    var reconnectTime: TimeInterval = 0
    public func reconnect() {
        self.close()
        if reconnectTime > 64 { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectTime) {
            self.socket = nil
            self.connect(self.websocketURL)
        }
        if reconnectTime == 0 {
            reconnectTime = 2
        } else {
            reconnectTime *= 2
        }
    }
    
    public func close() {
        guard let socket = socket else { return }
        socket.close()
        self.socket = nil
        self.destoryHeartbeat()
    }
  
    
    public func sendMsg(_ msg: Any) {
        DispatchQueue(label: "com.websocket.send.queue").async {
            guard let socket = self.socket else { return }
            if socket.readyState == .OPEN {
                socket.send(msg)
            } else if socket.readyState == .CONNECTING {
                self.reconnect()
            } else if socket.readyState == .CLOSED || socket.readyState == .CLOSING {
                self.reconnect()
            } else {
                self.close()
            }
        }
    }
    
    fileprivate func heartbeat() {
        DispatchQueue.main.async {
            if let _ = self.heartbeat_timer { return }
            self.destoryHeartbeat()
            self.heartbeat_timer = Timer.scheduledTimer(withTimeInterval: 3 * 60,
                                                        repeats: true,
                                                        block: { [weak self] timer in
                                                            guard let `self` = self else { return }
                                                            self.sendMsg(["heart":"heart"])
            })
        }
    }
    
    private func destoryHeartbeat() {
        DispatchQueue.main.async {
            if let _ = self.heartbeat_timer {
                self.heartbeat_timer?.invalidate()
                self.heartbeat_timer = nil
            }
        }
    }
}

extension WebSocketMgr: SRWebSocketDelegate {
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        print("receive \(message)")
        delegate?.webSocketDidReceiveMessage(message)
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        print("websocket did open")
        reconnectTime = 0
        self.heartbeat()
        if webSocket == socket {
            
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        print("websocket did receive pong")
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        print("websocket did fail, error:\(error)")
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("websocket did close; code:\(code), reason:\(reason)")
    }
}


