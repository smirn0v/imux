//
//  main.m
//  imux
//
//  Created by Smirnov on 1/4/13.
//  Copyright (c) 2013 Borsch Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "mobiledevice.h"
#include "utils.h"

volatile am_device_t target_device = NULL;

NSString* am_deviceIdentifier(am_device_t device) {
    CFStringRef deviceIdentifier = AMDeviceCopyDeviceIdentifier(device);
    return [((NSString*)deviceIdentifier) autorelease];
}

void am_notification_handler(struct am_device_notification_callback_info * notificationInfo) {
    @autoreleasepool {
        NSString* deviceIdentifier = am_deviceIdentifier(notificationInfo->dev);
        if(notificationInfo->msg == ADNCI_MSG_CONNECTED) {
            printf("[%s] connected\n",deviceIdentifier.UTF8String);
            if(AMDeviceConnect(notificationInfo->dev)!=0) {
                printf("[%s] failed to AMDeviceConnect\n",deviceIdentifier.UTF8String);
                return;
            }
            
            int interface_type = AMDeviceGetInterfaceType(notificationInfo->dev);
            
            if(interface_type != 1) {
                printf("[%s] non usb connection, ignoring\n",deviceIdentifier.UTF8String);
                return;
            }
            
            target_device = notificationInfo->dev;
        }
        if(notificationInfo->msg == ADNCI_MSG_DISCONNECTED) {
            printf("[%s] disconnected\n", deviceIdentifier.UTF8String);
            if(notificationInfo->dev == target_device) {
                target_device = NULL;
            }
        }
    }
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
        
        am_device_callbacks_t callbacks;
        int result = AMDeviceNotificationSubscribe(am_notification_handler, 0, 0, 0, &callbacks);
        
        if(result != 0) {
            fprintf(stderr,"[-] failed to subscribe to iDevice notifications");
            exit(-1);
        }
        
        int server_socket = util_start_tcp_server(31337);
        
        if(server_socket <= 0) {
            fprintf(stderr,"[-] failed to start local tcp server at port '%d'", 31337);
            exit(-1);
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while(1) {
                util_accept_connection(server_socket, ^(int client_socket) {
                    am_device_t device = target_device;
                    int iphone_socket;
                    if(!device)
                        return;
                    printf("[+] Got a local connection\n");
                    muxconn_t connection_id = AMDeviceGetConnectionID(device);
                    int ret = USBMuxConnectByPort(connection_id, htons(22), &iphone_socket);
                    
                    if(ret!=0) {
                        fprintf(stderr,"[-] failed to perform mux connect on device");
                        return;
                    }
                    printf("[+] Tying local connection with iDevice\n");
                    util_tie_in_sockets(client_socket, iphone_socket);
                });
            }
        });

        [runLoop run];
    }
    return 0;
}

