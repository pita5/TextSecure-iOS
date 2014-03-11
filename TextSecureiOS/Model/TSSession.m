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
#import "TSChain.h"
#import "TSPreKeyWhisperMessage.hh"

@interface TSSession (){
    TSChainKey *senderChainKey;
    NSMutableArray *receiverChains;
}
@end

@implementation TSSession

- (instancetype)initWithContact:(TSContact*)contact deviceId:(int)deviceId{
    self = [super init];
    if (self) {
        _contact = contact;
        _deviceId = deviceId;
    }
    return self;
}

- (NSData*)theirIdentityKey{
    return self.contact.identityKey;
}

- (BOOL)hasPendingPrekey{
    return self.preKey != nil;
}

- (BOOL)hasSenderChain{
    return self.senderChainKey != nil;
}

- (TSChainKey*)senderChainKey{
    return senderChainKey;
}

- (void)setSenderChain:(TSECKeyPair*)senderEphemeralPair chainkey:(TSChainKey*)chainKey{
    self.senderChainKey = chainKey;
    self.senderEphemeral = senderEphemeralPair;
}

- (void)setSenderChainKey:(TSChainKey*)chainKey{
    senderChainKey = chainKey;
}

- (BOOL)hasReceiverChain:(NSData*) ephemeral{
    return [self receiverChainKey:ephemeral];
}

- (TSChainKey*)receiverChainKey:(NSData*)senderEphemeral{
    return [self receiverChain:senderEphemeral].chainKey;
}

- (TSChain*)receiverChain:(NSData*)senderEphemeral{
    int index = 0;
    for(TSChain *chain in receiverChains){
        if ([chain.ephemeral isEqualToData:senderEphemeral]) {
            chain.chainKey.index = index;
            return chain;
        }
        index ++;
    }
    return nil;
}

- (void)addReceiverChain:(NSData*)senderEphemeral chainKey:(TSChainKey*)chainKey{
    
    TSChain *chain = [[TSChain alloc]initWithChainKey:chainKey epehemeral:senderEphemeral];
    
    if ([receiverChains count] > 4) {
        [receiverChains removeObjectAtIndex:0];
    }
    chainKey.index = (int)[receiverChains count] - 1;
    [receiverChains addObject:chain];
}

- (void)setReceiverChainKeyWithEphemeral:(NSData*)senderEphemeral chainKey:(TSChainKey*)chainKey{
    
    TSChain *chain = [self receiverChain:senderEphemeral];
    
    TSChain *newChain = [[TSChain alloc] initWithChainKey:chainKey epehemeral:senderEphemeral];
    
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

- (void)removeMessageKeysForEphemeral:(NSData*)ephemeral counter:(int)counter{
#warning to be implemented
}

- (void)setMessageKeysWithEphemeral:(NSData*)ephemeral messageKey:(TSMessageKeys*)messageKeys{
    
    TSChain *chain = [self receiverChain:ephemeral];
    [chain.messageKeys addObject:messageKeys];

}

#pragma mark Helper method


- (void)save{
#warning not implemented
}

/**
 *  The clear method removes all keying material of a session. Only properties remaining are the necessary deviceId and contact information
 */

- (void)clear{
    senderChainKey = nil;
    receiverChains = [NSMutableArray array];
    self.theirEphemeralKey = nil;
    self.rootKey = nil;
    self.ephemeralReceiving = nil;
    self.senderEphemeral = nil;
    self.PN = 0;
    self.preKey = nil;
}

@end
