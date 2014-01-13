//
//  MessagesManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 30/11/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesManager.h"
#import "TSAxolotlRatchet.hh"
#import "TSMessage.h"
#import "NSData+Base64.h"

@implementation TSMessagesManager


+ (id)sharedManager {
    static TSMessagesManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)receiveMessagePush:(NSDictionary *)pushInfo{
  [TSAxolotlRatchet processIncomingMessage:[NSData  dataFromBase64String:[pushInfo objectForKey:@"m"]]];

}

-(void) sendMessage:(TSMessage*)message onThread:(TSThread*)thread ofType:(TSWhisperMessageType) messageType{
  [TSAxolotlRatchet processOutgoingMessage:message onThread:thread ofType:messageType];
  
}



@end
