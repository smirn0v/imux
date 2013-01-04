#ifndef MOBILEDEVICE_H_
#define MOBILEDEVICE_H_

#ifdef __cplusplus
extern "C" {
#endif
    
#define ADNCI_MSG_CONNECTED     1
#define ADNCI_MSG_DISCONNECTED  2
#define ADNCI_MSG_UNKNOWN       3
    
    typedef void* am_device_t;
    typedef void* am_device_callbacks_t;
    typedef int muxconn_t;
    struct am_device_notification_callback_info
    {
        am_device_t dev;  /* 0    device */
        unsigned int msg;       /* 4    one of ADNCI_MSG_* */
    };
    typedef void (*am_device_notification_callback_t)(struct am_device_notification_callback_info *);
    
    CFStringRef AMDeviceCopyDeviceIdentifier(am_device_t device);
    
    int AMDeviceNotificationSubscribe(am_device_notification_callback_t notificationCallback, int , int, int , am_device_callbacks_t *callbacks);
    
    int AMDeviceGetInterfaceType(am_device_t device);
    
    int AMDeviceConnect(am_device_t am_device);
    int AMDeviceDisconnect(am_device_t am_device);
    
    muxconn_t AMDeviceGetConnectionID(am_device_t device);
    
    int USBMuxConnectByPort(muxconn_t muxConn, short netPort, int* sockHandle);
    
#ifdef __cplusplus
}
#endif

#endif