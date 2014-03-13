//
//  TSChainKey.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 02/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSChainKey.h"
#import "TSHKDF.h"
#import "TSMessageKeys.h"
#import "Cryptography.h"

@implementation TSChainKey

static NSString * const kChainKeyKey   = @"kChainKeyKey";
static NSString * const kChainKeyIndex = @"kChainKeyIndex";

- (instancetype)initWithChainKeyWithKey:(NSData*)key index:(int)index{
    self = [super init];
    if (self) {
        _key   = key;
        _index = index;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    
    if (self) {
        _key   = [aDecoder decodeObjectForKey:kChainKeyKey];
        _index = [aDecoder decodeIntForKey:kChainKeyIndex];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.key forKey:kChainKeyKey];
    [aCoder encodeInteger:self.index forKey:kChainKeyIndex];
}

- (TSMessageKeys*)messageKeys{
    int hmacKeyMK  = 0x01;
    
    NSData* nextMK = [Cryptography computeHMAC:self.key withHMACKey:[NSData dataWithBytes:&hmacKeyMK length:sizeof(hmacKeyMK)]];

    return [self deriveTSMessageKeysFromMessageKey:nextMK];
}

- (TSMessageKeys*)deriveTSMessageKeysFromMessageKey:(NSData*)nextMessageKey_MK {
    NSData* newCipherKeyAndMacKey  = [TSHKDF deriveKeyFromMaterial:nextMessageKey_MK outputLength:64 info:[@"WhisperMessageKeys" dataUsingEncoding:NSUTF8StringEncoding]];
    NSData* cipherKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(0, 32)];
    NSData* macKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(32, 32)];
    return [[TSMessageKeys alloc] initWithCipherKey:cipherKey macKey:macKey counter:self.index];
}

- (TSChainKey*)nextChainKey{
    int hmacKeyCK  = 0x02;
    NSData* nextCK = [Cryptography computeHMAC:self.key  withHMACKey:[NSData dataWithBytes:&hmacKeyCK length:sizeof(hmacKeyCK)]];
    return [[TSChainKey alloc] initWithChainKeyWithKey:nextCK index:self.index+1];
}

@end
