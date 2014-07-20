//
//  TSSocketManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 17/05/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "Constants.h"
#import "TSSocketManager.h"

#define kWebSocketHeartBeat 15

@interface TSSocketManager ()
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) SRWebSocket *websocket;
@end

@implementation TSSocketManager

- (id)init{
    self = [super init];
    
    if (self) {
        self.websocket = nil;
    }
    
    return self;
}

+ (id)sharedManager {
    static TSSocketManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

#pragma mark - Manage Socket

+ (void)becomeActive{
    SRWebSocket *socket =[[self sharedManager] websocket];
    
    if (socket) {
        switch ([socket readyState]) {
            case SR_OPEN:
                DLog(@"WebSocket already open on connection request");
                return;
            case SR_CONNECTING:
                DLog(@"WebSocket is already connecting");
                [socket open];
                return;
            default:
                [socket close];
                socket.delegate = nil;
                socket = nil;
                break;
        }
    }
    
    NSString *webSocketConnect = [NSString stringWithFormat:@"%@?login=%@&password=%@", textSecureWebSocketAPI, [[TSKeyManager getUsernameToken] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"],[TSKeyManager getAuthenticationToken]];
    NSURL *webSocketConnectURL = [NSURL URLWithString:webSocketConnect];
    NSLog(@"WebsocketURL %@", webSocketConnectURL);
    socket = [[SRWebSocket alloc] initWithURL:webSocketConnectURL];
    socket.delegate = [self sharedManager];
    [socket setHeartbeatInterval:kWebSocketHeartBeat];
    [socket open];
}

+ (void)resignActivity{
    SRWebSocket *socket =[[self sharedManager] websocket];
    int state = [socket readyState];

    if (state == SR_CONNECTING || state == SR_OPEN) {
        [socket close];
        DLog(@"Socket closed");
    }
    socket.delegate = nil;
    socket = nil;
}

#pragma mark - Delegate methods

- (void) webSocketDidOpen:(SRWebSocket *)webSocket{
    DLog(@"WebSocket was sucessfully opened");
    self.timer = [NSTimer timerWithTimeInterval:kWebSocketHeartBeat target:self selector:@selector(webSocketHeartBeat) userInfo:nil repeats:YES];
}

- (void) webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    DLog(@"Error connecting to socket %@", error);
    [self.timer invalidate];
}

- (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    DLog(@"Received on Websocket : %@", message);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    [self.timer invalidate];
}

- (void)webSocketHeartBeat{
    // Send heartbeat. See: https://github.com/square/SocketRocket/pull/184
}

@end
