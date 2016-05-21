//
//  DNSServerQuery.swift
//  SimpleTunnel
//
//  Copyright © 2015年 Apple Inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
@objc class DNSServerQuery:NSObject ,GCDAsyncUdpSocketDelegate{
    var  queryDomains:[String] = []
    var  address:NSData?
    var  packet:DNSPacket?
    var  socket:GCDAsyncUdpSocket?
    func sendQuery(){
        let dispatchQueue = dispatch_queue_create("query", nil);
        socket = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: dispatchQueue)
        //socket?.sendData(packet?.rawData, toHost: , port: <#T##UInt16#>, withTimeout: <#T##NSTimeInterval#>, tag: <#T##Int#>)
    }
}
