//
//  SocketMgr.swift
//  NetWorkTool
//
//  Created by y2ss on 2018/9/21.
//  Copyright © 2018年 y2ss. All rights reserved.
//

import Foundation

class SocketMgr: NSObject {
    
    private static let HOST = "localhost"
    private static let PORT: UInt16 = 8333
    private static var __instance = SocketMgr()
    
    class var shared: SocketMgr {
        return __instance
    }
    
    private var socket: GCDAsyncSocket!
    private override init() {
        super.init()
        socket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
    }
    
    @discardableResult
    func connect() -> Bool {
        do {
            try socket.connect(toHost: SocketMgr.HOST, onPort: SocketMgr.PORT, withTimeout: -1)
            return true
        } catch {
            print(error)
            return false
        }
    }

    func disconnect() {
        socket.disconnect()
    }
    
    func sendMsg(_ msg: String) {
        if let data = msg.data(using: .utf8) {
            socket.write(data, withTimeout: -1, tag: 333)
        }
    }
    
    func pullTheMsg() {
        socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: 10, maxLength: 50000, tag: 333)
        //监听读数据的代理，只能监听10秒，10秒过后调用代理方法  -1永远监听，不超时，但是只收一次消息，
    }
    
    //用Pingpong机制来看是否有反馈
    func checkPingPoing() {
        socket.readData(withTimeout: -1, tag: 333)
    }
}

extension SocketMgr: GCDAsyncSocketDelegate  {
    
    
    //连接成功调用
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("连接成功host:\(host),port:\(port)")
        
        checkPingPoing()
        //心跳写在这...
    }
    
    //断开连接的时候调用
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if let error = err {
            print("连接断开error:\(error)")
        }
        //断线重连写在这..
    }
    
    //写的回调
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("写的回调,tag:\(tag)")
        //判断是否成功发送，如果没收到响应，则说明连接断了，则想办法重连
        checkPingPoing()
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if let msg = String(data: data, encoding: .utf8) {
            print(msg)
            pullTheMsg()
        }
    }
    
}
