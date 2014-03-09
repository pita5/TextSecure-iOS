//
//  TSSession.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSUserKeysDatabase.h"
#import "TSSession.h"
#import "TSMessage.h"
#import "TSPreKeyWhisperMessage.hh"

@implementation TSSession

// Initialize Session with PreKey Message

// Methods for getting session?

- (instancetype)initOrCreateWithContact:(TSContact *)contact deviceId:(int)deviceId preKeyWhisperMessage:(TSEncryptedWhisperMessage*)message{
    
    self = [TSMessagesDatabase sessionForRegisteredId:contact.registeredID deviceId:deviceId];
    
    if (!self) {
        self = [super init];
    }
    

    
    if (self) {
        _contact = contact;
        _deviceId = deviceId?:1;
        _theirEphemeralKey = [message ephemeralKey];
        
        if ([message isKindOfClass:[TSPreKeyWhisperMessage class]]) {
            TSPreKeyWhisperMessage *preKeyWhisperMessage = (TSPreKeyWhisperMessage*)message;
        }
    }
    return self;
}

- (instancetype)initWithContact:(TSContact *)contact deviceId:(int)deviceId preKeyWhisperMessage:(TSEncryptedWhisperMessage*)message{
    
}

- (NSData*)theirIdentityKey{
    return self.contact.identityKey;
}



@end
