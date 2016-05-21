//
//  SysUtil.h
//  SimpleTunnel
//
//  Created by network extension on 15/10/21.
//  Copyright © 2015年 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <resolv.h>
#include <dns_sd.h>
@interface DNSPacket:NSObject {
    
}
@end
@interface SysUtil : NSObject
+ (NSString*)loadSystemDNSServer;
@end
