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


/**
 * Generate a Curve25519 key pair.
 * @author Alban Diquet
 *
 * @param preKeyId The TextSecure preKeyId to assign to the newly generated key pair. See https://github.com/WhisperSystems/TextSecure/wiki/ProtocolV2 for more information.
 * @return A reference to the newly generated key pair or nil if memory could not be allocated.
 */
+(instancetype) keyPairGenerateWithPreKeyId:(int32_t)preKeyId;


/**
 * Export the key pair's public key.
 * @author Alban Diquet
 *
 * @return The key pair's public key.
 */
-(NSData*) publicKey;

/**
 * Return the key pair's preKeyId.
 * @author Alban Diquet
 *
 * @return The key pair's preKeyId.
 */
-(int32_t) preKeyId;


/**
 * Compute a shared secret using the supplied third-party public key and the key pair's private key. See https://code.google.com/p/curve25519-donna/ for more information.
 * @author Alban Diquet
 *
 * @return The shared secret.
 */
-(NSData*) generateSharedSecretFromPublicKey:(NSData*)theirPublicKey;


@end
