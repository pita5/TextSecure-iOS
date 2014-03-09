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
#import "TSMessageKeys.h"
#import "TSPrekey.h"
#import "TSChainKey.h"
#import "TSEncryptedWhisperMessage.hh"

@interface TSSession : NSObject

@property(readonly)int deviceId;
@property(readonly)TSContact *contact;

@property(copy)NSData *theirEphemeralKey;
@property(readwrite)NSData *rootKey;

@property NSData *ephemeralReceiving;
@property TSECKeyPair *ephemeralOutgoing;
@property int PN;


#pragma mark Prekey methods (non-persistent)

- (BOOL)hasPendingPrekey;
- (TSPrekey*)pendingPrekey;

- (TSSession*)initWithContact:(TSContact*)contact deviceId:(int)deviceId;
- (NSData*)theirIdentityKey;

- (BOOL)hasReceiverChain:(NSData*) ephemeral;
- (BOOL)hasSenderChain;

- (TSChainKey*)receiverChainKey:(NSData*)senderEphemeral;
- (TSChainKey*)senderChainKey;
- (TSECKeyPair*)senderEphemeral;

- (TSChainKey*)addReceiverChain:(NSData*)senderEphemeral chainKey:(TSChainKey*)chainKey;
- (void) setReceiverChainKeyWithEphemeral:(NSData*)senderEphemeral chainKey:(TSChainKey*)chainKey;
- (TSChainKey*)setSenderChain:(TSECKeyPair*)senderEphemeralPair chainkey:(TSChainKey*)chainKey;
- (void)setSenderChainKey:(TSChainKey*)chainKey;

- (BOOL)hasMessageKeysForEphemeral:(NSData*)ephemeral counter:(int)counter;
- (void)removeMessageKeysForEphemeral:(NSData*)ephemeral counter:(int)counter;

- (void)setMessageKeysWithEphemeral:(NSData*)ephemeral messageKey:(TSMessageKeys*)messageKeys;

@end
