//
//  TSECKeyPair.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//


@interface TSECKeyPair : NSObject<NSCoding> {

    uint8_t publicKey[32];
    uint8_t privateKey[32];
    int32_t preKeyId;
}


+(instancetype) keyPairGenerateWithKeyId:(int32_t)preKeyId;

-(NSData*) getPublicKey;
-(NSData*) generateSharedSecretFromPublicKey:(NSData*)theirPublicKey;


@end
