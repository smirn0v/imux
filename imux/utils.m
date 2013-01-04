//
//  utils.c
//  imux
//
//  Created by Smirnov on 1/4/13.
//  Copyright (c) 2013 Borsch Lab. All rights reserved.
//

#include "utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <strings.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

int util_start_tcp_server(int port) {
    int server_socket;
    struct sockaddr_in server_addr;
    
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0)
        return -1;
    
    bzero((char *) &server_addr, sizeof(server_addr));
    
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(port);
    
    if (bind(server_socket, (struct sockaddr *) &server_addr, sizeof(server_addr)) < 0) {
        close(server_socket);
        return -1;
    }
    
    if(listen(server_socket,5) !=0) {
        close(server_socket);
        return -1;
    }
    
    return server_socket;
}

int util_accept_connection(int server_socket, void(^handler)(int client_socket)) {
    int client_socket;
    socklen_t length;
    struct sockaddr_in client_addr;
    
    length = sizeof(client_addr);
    client_socket = accept(server_socket,
                           (struct sockaddr *) &client_addr,
                           &length);
    
    if (client_socket < 0)
        return -1;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        handler(client_socket);
        close(client_socket);
    });
    
    return 0;
}

void util_tie_in_sockets(int socket1, int socket2) {
    fd_set read_set;
    
    struct timeval timeout;
    timeout.tv_usec = 0;
    timeout.tv_sec  = 240;
    
    const long buffer_size = 1024;
    char* buffer = (char*)malloc(buffer_size);
    
    if(!buffer)
        return;
    
    long(^redirect)(int,int,fd_set*) = ^(int s1, int s2, fd_set* set) {
        if(FD_ISSET(s1, set)) {
            ssize_t bytes_recvd = recv(s1, buffer, buffer_size, 0);
            if(bytes_recvd <= 0) {
                return (long)-1;
            }
            
            char* p = buffer;
            ssize_t overall_bytes_sent = 0;
        
            while(overall_bytes_sent != bytes_recvd) {
                ssize_t bytes_sent = write(s2, p, bytes_recvd - overall_bytes_sent);
                
                if(bytes_sent < 0)
                    return (long) -1;
                
                overall_bytes_sent += bytes_sent;
                p+=bytes_sent;
            }
        }
        return (long)0;
    };
    
    FD_ZERO(&read_set);
    
    int activity = 1;
    while(activity >=0 || errno != EINTR) {
        FD_SET(socket1, &read_set);
        FD_SET(socket2, &read_set);
        
        activity = select(FD_SETSIZE, &read_set, NULL, NULL, &timeout);

        if(activity >= 0) {

            long res = 0;
            
            res = redirect(socket1,socket2,&read_set);
            
            if(res != 0)
                break;
            
            res = redirect(socket2,socket1,&read_set);
           
            if(res != 0)
                break;
            
        }
    }
    
    free(buffer);
}

