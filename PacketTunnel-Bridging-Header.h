//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#import "SysUtil.h"
void set_config(const char *server, const char *remote_port, const char* password, const char* method);
int local_main();
int stopSocks();
#import <CocoaAsyncSocket/AsyncSocket.h>
#import "CocoaAsyncSocket/GCDAsyncUdpSocket.h"
