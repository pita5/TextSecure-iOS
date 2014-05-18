//
//  TSSocketManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 17/05/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "Constants.h"
#import "TSSocketManager.h"

@interface TSSocketManager ()
@property (nonatomic, retain) SRWebSocket *websocket;
@end

@implementation TSSocketManager

- (id)init{
    self = [super init];
    
    if (self) {
        NSString *webSocketConnect = [NSString stringWithFormat:@"%@?user=%@&password=%@", textSecureWebSocketAPI, [[TSKeyManager getUsernameToken] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"],[TSKeyManager getAuthenticationToken]];
        NSURL *webSocketConnectURL = [NSURL URLWithString:webSocketConnect];
        NSLog(@"WebsocketURL %@", webSocketConnectURL);
        self.websocket = [[SRWebSocket alloc] initWithURL:webSocketConnectURL];
        self.websocket.delegate = self;
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
    DLog(@"Socket resuming activity");
    [[[self sharedManager] websocket] open];
}

+ (void)resignActivity{
    DLog(@"Socket resigning activity");
}

#pragma mark - Delegate methods

- (void) webSocketDidOpen:(SRWebSocket *)webSocket{
    NSLog(@"WebSocket was sucessfully opened");
}

- (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
}

- (void) webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    DLog(@"Error connecting to socket %@", error);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    
}

@end
