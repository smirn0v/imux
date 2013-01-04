//
//  main.m
//  imux
//
//  Created by Smirnov on 1/4/13.
//  Copyright (c) 2013 Borsch Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "mobiledevice.h"


void am_notification_handler(struct am_device_notification_callback_info * notificationInfo) {
    NSLog(@"Notification");
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
        
        am_device_callbacks_t callbacks;
        AMDeviceNotificationSubscribe(am_notification_handler, 0, 0, 0, &callbacks);

        [runLoop run];
    }
    return 0;
}

