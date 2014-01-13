//
//  MessagesManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 30/11/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesManager.h"
#import "TSContact.h"
#import "NSData+Base64.h"
#import "TSSubmitMessageRequest.h"
#import "TSMessagesManager.h"
#import "TSKeyManager.h"
#import "Cryptography.h"
#import "TSMessage.h"
#import "TSMessagesDatabase.h"
#import "TSUserKeysDatabase.h"
#import "TSThread.h"
#import "TSMessageSignal.hh"
#import "TSPushMessageContent.hh"
#import "TSWhisperMessage.hh"
#import "TSEncryptedWhisperMessage.hh"
#import "TSPreKeyWhisperMessage.hh"
#import "TSECKeyPair.h"
#import "TSRecipientPrekeyRequest.h"
#import "TSWhisperMessageKeys.h"
#import "TSHKDF.h"
#import "TSParticipants.h"
#import "TSAxolotlRatchet.h"


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
