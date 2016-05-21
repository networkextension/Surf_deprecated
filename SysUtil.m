//
//  SysUtil.m
//  SimpleTunnel
//
//  Created by network extension  on 15/10/21.
//  Copyright © 2015年 Apple Inc. All rights reserved.
//
#include <arpa/inet.h>
#import "SysUtil.h"

@implementation SysUtil
+ (NSString*)loadSystemDNSServer {
    NSString *_systemDNSServer;
    res_init();
    if (_res.nscount > 0) {
        struct in_addr addr = _res.nsaddr_list[0].sin_addr;
        _systemDNSServer = @(inet_ntoa(addr));
    } else {
        _systemDNSServer = nil;
    }
    return _systemDNSServer;
}
@end
