//
//  TSSocketManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 17/05/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "Constants.h"
#import "TSSocketManager.h"
#import "TSMessagesManager.h"
#import "TSStorageMasterKey.h"
#import "TSWaitingPushMessageDatabase.h"

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
    [[self sharedManager] setWebsocket:socket];
}

+ (void)resignActivity{
    SRWebSocket *socket =[[self sharedManager] websocket];
    [socket close];
}

#pragma mark - Delegate methods

- (void) webSocketDidOpen:(SRWebSocket *)webSocket{
    DLog(@"WebSocket was sucessfully opened");
    self.timer = [NSTimer scheduledTimerWithTimeInterval:kWebSocketHeartBeat target:self selector:@selector(webSocketHeartBeat) userInfo:nil repeats:YES];
}

- (void) webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    DLog(@"Error connecting to socket %@", error);
    [self.timer invalidate];
}

- (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{

    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *serializedMessage = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    
    if(![TSStorageMasterKey isStorageMasterKeyLocked]) {
        [[TSMessagesManager sharedManager]receiveMessagePush:serializedMessage];
    }
    else {
        DLog(@"Got message on the socket while storage db was closed.");
    }
    
    DLog(@"Got message : %@", [serializedMessage objectForKey:@"message"]);
    
    NSString *ackedId = [serializedMessage objectForKey:@"id"];
    [self.websocket send:[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"type":@"1", @"id":ackedId} options:0 error:nil] encoding:NSUTF8StringEncoding]];
    DLog(@"ACK sent : %@", ackedId);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    DLog(@"WebSocket did close");
    [self.timer invalidate];
}

- (void)webSocketHeartBeat{
    // Send heartbeat. See: https://github.com/square/SocketRocket/pull/184
}

@end
