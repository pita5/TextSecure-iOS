//
//  TSChainKey.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 02/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSChainKey.h"
#import "TSMessageKeys.h"
#import "TSDerivedSecrets.h"
#import "Cryptography.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation TSChainKey


#define kTSKeySeedLength 1

static uint8_t kMessageKeySeed[kTSKeySeedLength]    = {01};
static uint8_t kChainKeySeed[kTSKeySeedLength]      = {02};

static NSString * const kChainKeyKey                = @"kChainKeyKey";
static NSString * const kChainKeyIndex              = @"kChainKeyIndex";

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
    NSData *inputKeyMaterial = [self getBaseMaterial:[NSData dataWithBytes:kMessageKeySeed length:kTSKeySeedLength]];
    TSDerivedSecrets *derivedSecrets = [TSDerivedSecrets derivedMessageKeysWithData:inputKeyMaterial];
    return [[TSMessageKeys alloc] initWithCipherKey:derivedSecrets.cipherKey macKey:derivedSecrets.macKey counter:self.index];
}

- (TSChainKey*) nextChainKey{
    NSData* nextCK = [self getBaseMaterial:[NSData dataWithBytes:kChainKeySeed length:kTSKeySeedLength]];
    return [[TSChainKey alloc] initWithChainKeyWithKey:nextCK index:self.index+1];
}

- (NSString*) debugDescription {
    return [NSString stringWithFormat:@"CK: %@",self.key];
}

- (NSData*)getBaseMaterial:(NSData*)seed{
    uint8_t result[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA256, [self.key bytes], [self.key length]);
    CCHmacUpdate(&ctx, [seed bytes], [seed length]);
    CCHmacFinal(&ctx, result);
    return [NSData dataWithBytes:result length:sizeof(result)];
}

@end
