//
//  DNSServer.swift
//  SimpleTunnel
//
//  Copyright © 2015年 Apple Inc. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import SimpleTunnelServices
@objc class DNSServer:NSObject, GCDAsyncUdpSocketDelegate{
    var domains:[String] = []
    var clientAddress:NSData?
    var packet:DNSPacket?
    var socket:GCDAsyncUdpSocket?
    var waittingQueriesMap:[UInt16:AnyObject] = [:]
    var queries:[DNSPacket] = []
    var queryIDCounter:UInt16 = 0
    let dispatchQueue = dispatch_queue_create("DNSServer", nil);
    override init () {
        super.init()
        socket = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: dispatchQueue)
        //socket = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: dispatchQueue)
    }
    func addQuery(didReceiveData data:NSData!) {
        let packet:DNSPacket = DNSPacket()//= DNSPacket.init(packetData: data)
        
        queries.append(packet)
        //processQuery()
        myLog("receive udp packet \(data)")
    }
   
    func processQuery() {
        var data:NSData = NSData()//(queries.first?.rawData)! as! NSMutableData
        queries.removeFirst()
        if (queryIDCounter == UInt16(UINT16_MAX)) {
            queryIDCounter = 0
        }
        
        let  queryID:UInt16 = queryIDCounter++;
        //data.replaceBytesInRange(NSMakeRange(0, 2), withBytes: queryID)
        
        //[data replaceBytesInRange:NSMakeRange(0, 2) withBytes:&queryID];
        //how to send data
        waittingQueriesMap[queryID] = data
        socket?.sendData(data, toHost: "192.168.0.254", port: 54, withTimeout: 10, tag: 0)
    }
    func processResponse(datagrams:[NSData]) ->Void{
        dispatch_async(dispatchQueue) { () -> Void in
            
            for data in datagrams{
                let queryID:UInt16 = 0 //= data.bytes
                let query = self.waittingQueriesMap[queryID] as? DNSServerQuery
                //DNSServerQuery *query = _waittingQueriesMap[@(queryID)];
                guard let _ = query else{
                    myLog("Local query not found!")
                    return
                }
                //NSMutableData *mdata = [data mutableCopy];
                //u_int16_t identifier = query.packet.identifier;
                //[mdata replaceBytesInRange:NSMakeRange(0, 2) withBytes:&identifier];
                
                //[_socket sendData:mdata toAddress:query.clientAddress withTimeout:10 tag:0];
                self.socket?.sendData(data, toAddress: query!.address, withTimeout: 10, tag: 0)
                

                
            }
            
        }
    }
}
