//
//  TSSession.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSContact.h"
#import "TSPreKeyWhisperMessage.hh"
#import "RKCK.h"
#import "TSChainKey.h"
#import "TSWhisperMessageKeys.h"

@interface TSSession : NSObject

@property(readonly)NSString *sessionIdentifier;
@property(readonly)int deviceId;
@property(readonly)TSContact *contact;

@property(readonly)NSData *theirIdentityKey;
@property(copy)NSData *theirEphemeralKey;

#pragma mark Constructors

/**
 *  Constructor for outgoing message intializations
 *
 *  @param contact   TSContact we are sending the message to
 *  @param deviceId  Identifier int of receiving device
 *  @param ephemeral
 *
 *  @return returns the session instance
 */

- (instancetype)initWithContact:(TSContact*)contact deviceId:(int)deviceId ephemeral:(NSData*)ephemeral;


#pragma mark Identity

- (TSECKeyPair*)myIdentityKey;

#pragma mark Axolotl

- (int)previousCounter;
- (void)setPreviousCounter;

- (NSData*)rootKey;
- (BOOL)setRootKey:(NSData*)rootKey;

- (NSData*)senderEphemeralPublic;
- (TSECKeyPair*)senderEphemeral;

- (BOOL)setSenderEphemeral:(TSECKeyPair*)ephemeral;

- (void)setSenderChainWithKeyPair:(TSECKeyPair*)keyPair chainKey:(TSChainKey*)chainKey;

// GET OR CREATE RECEIVER CHAIN

- (TSChainKey*)getOrCreateChainKey:(NSData*)theirEphemeral;

- (BOOL)hasReceiverChain:(NSData*)theirEphemeral;

// GET OR CREATE SENDER CHAIN

- (TSChainKey*)getOrCreateSenderChain;

// HAS MESSAGE KEYS

- (TSWhisperMessage*)messageKeys;

// REMOVE MESSAGE KEYS

// SET MESSAGE KEYS

// SET RECEIVER CHAIN KEY

@end
