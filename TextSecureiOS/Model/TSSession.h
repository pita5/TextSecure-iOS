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

@interface TSSession : NSObject<NSCoding>

- (instancetype)initWithContact:(TSContact*)contact deviceId:(int)deviceId;
- (void)addContact:(TSContact*)contact deviceId:(int)deviceId;

@property(readonly)int deviceId;
@property(readonly)TSContact *contact;

@property NSData *rootKey;
@property int PN;
@property BOOL needsInitialization;

- (BOOL)isInitialized;

@property TSPrekey *pendingPreKey; // Prekey information to add in TSPrekeyWhisperMessage

- (BOOL)hasPendingPreKey;

- (BOOL)hasReceiverChain:(NSData*) ephemeral;
- (BOOL)hasSenderChain;

- (TSChainKey*)receiverChainKey:(NSData*)senderEphemeral;

- (void)setSenderChain:(TSECKeyPair*)senderEphemeralPair chainkey:(TSChainKey*)chainKey;
- (void)setSenderChainKey:(TSChainKey*)chainKey;
- (TSChainKey*)senderChainKey;

- (void)addReceiverChain:(NSData*)senderEphemeral chainKey:(TSChainKey*)chainKey;
- (void)setReceiverChainKeyWithEphemeral:(NSData*)senderEphemeral chainKey:(TSChainKey*)chainKey;

- (BOOL)hasMessageKeysForEphemeral:(NSData*)ephemeral counter:(int)counter;
- (TSMessageKeys*)removeMessageKeysForEphemeral:(NSData*)ephemeral counter:(int)counter;

- (void)setMessageKeysWithEphemeral:(NSData*)ephemeral messageKey:(TSMessageKeys*)messageKeys;

- (void)setSenderEphemeral:(TSECKeyPair*)ephemeralPair;

- (TSECKeyPair*)senderEphemeral;

#pragma mark Helper methods
- (NSData*)theirIdentityKey;

- (void)save;

/**
 *  The clear method removes all keying material of a session. Only properties remaining are the necessary deviceId and contact information
 */
- (void)removePendingPrekey;
- (void)clear;

@end
