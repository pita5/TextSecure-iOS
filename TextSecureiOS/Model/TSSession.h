//
//  TSSession.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSContact.h"
#import "RKCK.h"
#import "TSChain.h"
#import "TSWhisperMessageKeys.h"
#import "TSPrekey.h"
#import "TSEncryptedWhisperMessage.hh"

@interface TSSession : NSObject

@property(readonly)int deviceId;
@property(readonly)TSContact *contact;

@property(copy)NSData *theirEphemeralKey;
@property(readwrite)NSData *rootKey;

@property TSChain *receivingChain; // We want to store 5 of them
@property TSChain *sendingChain; 
@property NSData *ephemeralReceiving;
@property TSECKeyPair *ephemeralOutgoing;
@property int PN;

- (TSSession*)initWithContact:(TSContact*)contact deviceId:(int)deviceId;
- (NSData*)theirIdentityKey;

@end
