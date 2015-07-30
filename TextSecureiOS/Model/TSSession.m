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
#import "TSReceivingChain.h"
#import "TSSendingChain.h"
#import "TSPreKeyWhisperMessage.hh"

#pragma mark Keys for coder

static NSString* const kCoderPN               = @"kCoderPN";
static NSString* const kCoderRootKey          = @"kCoderRoot";
static NSString* const kCoderReceiverChains   = @"kCoderReceiverChains";
static NSString* const kCoderSendingChain     = @"kCoderSendingChain";
static NSString* const kCoderPendingPrekey    = @"kCoderPendingPrekey";


@interface TSSession (){
    TSSendingChain *senderChain;
    NSMutableArray *receiverChains;
}

@end

@implementation TSSession

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    
    if (self) {
        self.rootKey = [aDecoder decodeObjectForKey:kCoderRootKey];
        self.PN = [aDecoder decodeIntForKey:kCoderPN];
        self.pendingPreKey = [aDecoder decodeObjectForKey:kCoderPendingPrekey];
        senderChain = [aDecoder decodeObjectForKey:kCoderSendingChain];
        receiverChains = [[aDecoder decodeObjectForKey:kCoderReceiverChains] mutableCopy];
        self.needsInitialization = NO;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.rootKey forKey:kCoderRootKey];
    [aCoder encodeInt:self.PN forKey:kCoderPN];
    [aCoder encodeObject:senderChain forKey:kCoderSendingChain];
    [aCoder encodeObject:receiverChains forKey:kCoderReceiverChains];
    [aCoder encodeObject:self.pendingPreKey forKey:kCoderPendingPrekey];
}

- (void)addContact:(TSContact*)contact deviceId:(int)deviceId{
    _contact = contact;
    _deviceId = deviceId;
}

- (instancetype)initWithContact:(TSContact*)contact deviceId:(int)deviceId{
    self = [super init];
    if (self) {
        _contact = contact;
        _deviceId = deviceId;
        receiverChains = [NSMutableArray array];
        self.needsInitialization = NO;
    }
    return self;
}

- (NSData*)theirIdentityKey{
    return self.contact.identityKey;
}

- (BOOL)hasPendingPreKey{
    return self.pendingPreKey!= nil;
}

- (TSPrekey *)pendingPrekey{
    return self.pendingPrekey;
}

- (BOOL)hasSenderChain{
    return self.senderChainKey != nil;
}

- (BOOL)isInitialized{
    return self.rootKey?YES:NO;
}

- (TSChainKey*)senderChainKey{
    return senderChain.chainKey;
}

- (void)setSenderChain:(TSECKeyPair*)senderEphemeralPair chainkey:(TSChainKey*)chainKey{
    self.senderChainKey = chainKey;
    self.senderEphemeral = senderEphemeralPair;
}

- (void)setSenderChainKey:(TSChainKey*)chainKey{
    senderChain = [[TSSendingChain alloc] initWithChainKey:chainKey ephemeral:senderChain.ephemeral];
}

- (TSECKeyPair*)senderEphemeral{
    return senderChain.ephemeral;
}

- (void)setSenderEphemeral:(TSECKeyPair *)ephemeralPair{
    senderChain = [[TSSendingChain alloc] initWithChainKey:senderChain.chainKey ephemeral:ephemeralPair];
}

- (BOOL)hasReceiverChain:(NSData*) ephemeral{
    return [self receiverChainKey:ephemeral] != nil;
}

- (TSChainKey*)receiverChainKey:(NSData*)senderEphemeral{
    return [self receiverChain:senderEphemeral].chainKey;
}

- (TSReceivingChain*)receiverChain:(NSData*)senderEphemeral{
    for(TSReceivingChain *chain in receiverChains){
        if ([chain.ephemeral isEqualToData:senderEphemeral]) {
            return chain;
        }
    }
    return nil;
}

- (void)addReceiverChain:(NSData*)senderEphemeral chainKey:(TSChainKey*)chainKey{
    
    TSReceivingChain *chain = [[TSReceivingChain alloc]initWithChainKey:chainKey ephemeral:senderEphemeral];
    
    if ([receiverChains count] > 4) {
        [receiverChains removeObjectAtIndex:0];
    }
    [receiverChains addObject:chain];
}

- (void)setReceiverChainKeyWithEphemeral:(NSData*)senderEphemeral chainKey:(TSChainKey*)chainKey{
    
    TSReceivingChain *chain = [self receiverChain:senderEphemeral];
    
    TSReceivingChain *newChain = [[TSReceivingChain alloc] initWithChainKey:chainKey ephemeral:senderEphemeral];
    
    [receiverChains replaceObjectAtIndex:[receiverChains indexOfObject:chain] withObject:newChain];
}

- (BOOL)hasMessageKeysForEphemeral:(NSData*)ephemeral counter:(int)counter{
    for (TSMessageKeys *messageKeys in [self receiverChain:ephemeral].messageKeys){
        if (messageKeys.counter == counter) {
            return true;
        }
    }
    return false;
}

- (TSMessageKeys*)removeMessageKeysForEphemeral:(NSData*)ephemeral counter:(int)counter{
    for(NSUInteger i = 0; i <[[self receiverChain:ephemeral].messageKeys count]; i++){

        TSMessageKeys *messageKey = [[self receiverChain:ephemeral].messageKeys objectAtIndex:i];
        
        if (messageKey.counter == counter) {
            [[self receiverChain:ephemeral].messageKeys removeObjectAtIndex:i];
            return messageKey;
        }
    }
    @throw [NSException exceptionWithName:@"Message Key not found" reason:@"" userInfo:nil];
}

- (void)setMessageKeysWithEphemeral:(NSData*)ephemeral messageKey:(TSMessageKeys*)messageKeys{
    TSReceivingChain *chain = [self receiverChain:ephemeral];
    [chain.messageKeys addObject:messageKeys];
}

#pragma mark Helper method


- (void)save{
    [TSMessagesDatabase storeSession:self];
}

- (void)removePendingPrekey{
    self.pendingPreKey = nil;
}

/**
 *  The clear method removes all keying material of a session. Only properties remaining are the necessary deviceId and contact information
 */

- (void)clear{
    senderChain = nil;
    receiverChains = [NSMutableArray array];
    self.rootKey = nil;
    self.senderEphemeral = nil;
    self.PN = 0;
}

@end
