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

NSString *target_device_id = nil;

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
            
            if(target_device_id == nil) {
                printf("stick with first connected device [%s]\n", [deviceIdentifier cStringUsingEncoding: NSASCIIStringEncoding]);
                target_device_id = deviceIdentifier;
            }
            
            if([target_device_id isEqualToString: deviceIdentifier]) {
                
                
                target_device = notificationInfo->dev;
            }
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

        if(argc < 3) {
            fprintf(stderr, "usage: imux <localport> <remote port> [<device id>]\n");
            exit(1);
        }
        
        uint32_t localport = atoi(argv[1]);
        uint32_t remoteport = atoi(argv[2]);
        
        printf("local port    : %u\n",localport);
        printf("remote port   : %u\n",remoteport);
        
        if(argc == 4) {
            target_device_id = [NSString stringWithCString: argv[3] encoding: NSASCIIStringEncoding];
            
            printf("target device : %s\n", argv[3]);
        }
        
        am_device_callbacks_t callbacks;
        int result = AMDeviceNotificationSubscribe(am_notification_handler, 0, 0, 0, &callbacks);
        
        if(result != 0) {
            fprintf(stderr,"[-] failed to subscribe to iDevice notifications");
            exit(-1);
        }
        
        int server_socket = util_start_tcp_server(localport);
        
        if(server_socket <= 0) {
            fprintf(stderr,"[-] failed to start local tcp server at port '%d'", localport);
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
                    int ret = USBMuxConnectByPort(connection_id, htons(remoteport), &iphone_socket);
                    
                    if(ret!=0) {
                        fprintf(stderr,"[-] failed to perform mux connect on device");
                        return;
                    }
                    printf("[+] Tying local connection with iDevice[%s]\n",[target_device_id cStringUsingEncoding: NSASCIIStringEncoding]);
                    util_tie_in_sockets(client_socket, iphone_socket);
                });
            }
        });

        [runLoop run];
    }
    return 0;
}

