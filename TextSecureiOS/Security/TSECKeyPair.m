//
//  TSECKeyPair.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSECKeyPair.h"
#import "Cryptography.h"



// Used for serializing a TSECKeyPair
#define TSECKeyPairPublicKey @"TSECKeyPairPublicKey"
#define TSECKeyPairPrivateKey @"TSECKeyPairPrivateKey"
#define TSECKeyPairPreKeyId @"TSECKeyPairPreKeyId"


extern void curve25519_donna(unsigned char *output, const unsigned char *a, const unsigned char *b);


@implementation TSECKeyPair

# pragma mark Key pair generation

+(TSECKeyPair*) keyPairGenerateWithKeyId:(int32_t)prekeyId {
    
    TSECKeyPair* keyPair =[[TSECKeyPair alloc] init];
    if (keyPair == nil) {
        return nil;
    }
    
    keyPair->preKeyId = prekeyId;
    
    // Generate key pair as described in https://code.google.com/p/curve25519-donna/
    memcpy(keyPair->privateKey, [[Cryptography  generateRandomBytes:32] bytes], 32);
    keyPair->privateKey[0] &= 248;
    keyPair->privateKey[31] &= 127;
    keyPair->privateKey[31] |= 64;
    
    static const uint8_t basepoint[32] = {9};
    curve25519_donna(keyPair->publicKey, keyPair->privateKey, basepoint);
    
    return keyPair;
}


# pragma mark Key pair usage

-(NSData*) getPublicKey {
#warning for Android interoperability (and conforming to protocol) we will need to add leading byte of 0x05 to keys prior to sending/remove before using
    return [NSData dataWithBytes:self->publicKey length:32];
}


-(NSData*) generateSharedSecretFromPublicKey:(NSData*)theirPublicKey {
    unsigned char *sharedSecret = NULL;
    
    if ([theirPublicKey length] != 32) {
        @throw [NSException exceptionWithName:@"Invalid argument" reason:@" The supplied public key does not contain 32 bytes" userInfo:nil];
    }
    
    sharedSecret = malloc(32);
    if (sharedSecret == NULL) {
        return nil;
    }

    // Computing shared secret using our private key and the other party's public key
    curve25519_donna(sharedSecret,self->privateKey, (unsigned char*)[theirPublicKey bytes]);
    
    return [NSData dataWithBytes:sharedSecret length:32];
}


#pragma mark Key pair serialization

-(void) encodeWithCoder:(NSCoder *)coder {
    [coder encodeBytes:self->publicKey length:32 forKey:TSECKeyPairPublicKey];
    [coder encodeBytes:self->privateKey length:32 forKey:TSECKeyPairPrivateKey];
    [coder encodeInt32:self->preKeyId forKey:TSECKeyPairPreKeyId];
}


-(id) initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        unsigned int returnedLength = 0;
        const uint8_t *returnedBuffer = NULL;
        
        // De-serialize public key
        returnedBuffer = [coder decodeBytesForKey:TSECKeyPairPublicKey returnedLength:&returnedLength];
        if (returnedLength != 32) {
            return nil;
        }
        memcpy(self->publicKey, returnedBuffer, 32);
        
        // De-serialize private key
        returnedBuffer = [coder decodeBytesForKey:TSECKeyPairPrivateKey returnedLength:&returnedLength];
        if (returnedLength != 32) {
            return nil;
        }
        memcpy(self->privateKey, returnedBuffer, 32);
        
        // De-serialize preKeyId
        self->preKeyId = [coder decodeInt32ForKey:TSECKeyPairPreKeyId];
    }
    
    return self;
}


@end
