//
//  TSHKDF.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/7/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSHKDF : NSObject

/** ,
 * HMAC-based Key Derivation Function (HKDF) using the SHA-256 hash algorithm and no salt.
 * http://tools.ietf.org/html/rfc5869
 * @author Alban Diquet
 *
 * @param input Input keying material.
 * @param outputLength Size in bytes of the key material to generate.
 * @param info Application-specific information.
 * @return Key material derived from the input.
 */
+(NSData*) deriveKeyFromMaterial:(NSData *)input outputLength:(NSUInteger)outputLength info:(NSData *)info;


/** ,
 * HMAC-based Key Derivation Function (HKDF) using the SHA-256 hash algorithm.
 * http://tools.ietf.org/html/rfc5869
 * @author Alban Diquet
 *
 * @param input Input keying material.
 * @param outputLength Size in bytes of the key material to generate.
 * @param info Application-specific information.
 * @param salt Salt value.
 * @return Key material derived from the input.
 */
+(NSData*) deriveKeyFromMaterial:(NSData *)input outputLength:(NSUInteger)outputLength info:(NSData *)info salt:(NSData *)salt;

@end
