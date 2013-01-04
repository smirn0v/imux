//
//  utils.h
//  imux
//
//  Created by Smirnov on 1/4/13.
//  Copyright (c) 2013 Borsch Lab. All rights reserved.
//

#ifndef imux_utils_h
#define imux_utils_h

#ifdef __cplusplus
extern "C" {
#endif

    int util_start_tcp_server(int port);
    int util_accept_connection(int server_socket, void(^handler)(int client_socket));
    void util_tie_in_sockets(int socket1, int socket2);

    
#ifdef __cplusplus
}
#endif

#endif
