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
        // TO-DO <===
        NSString *webSocketConnect = [NSString stringWithFormat:@"%@", textSecureWebSocketAPI];
        NSURL *webSocketConnectURL = [NSURL URLWithString:webSocketConnect];
        self.websocket = [[SRWebSocket alloc] initWithURL:webSocketConnectURL];
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
    
}

+ (void)resignActivity{
    
}

#pragma mark - Delegate methods

- (void) webSocketDidOpen:(SRWebSocket *)webSocket{
    
}

- (void) webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
}

- (void) webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean{
    
}

@end
