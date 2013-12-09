//
//  TSHKDF.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/7/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSHKDF.h"
#include <CommonCrypto/CommonHMAC.h>
#include <CommonCrypto/CommonDigest.h>


// TextSecure HKDF constants
#define HKDF_HASH_ALG kCCHmacAlgSHA256
#define HKDF_HASH_LEN CC_SHA256_DIGEST_LENGTH


static const char *HKDFDefaultSalt[HKDF_HASH_LEN] = {0};


@implementation TSHKDF


+(NSData*) deriveKeyFromMaterial:(NSData *)input outputLength:(NSUInteger)outputLength info:(NSData *)info {
    NSData *defaultSalt = [NSData dataWithBytesNoCopy:HKDFDefaultSalt length:HKDF_HASH_LEN];
    return [TSHKDF deriveKeyFromMaterial:input outputLength:outputLength info:info salt:defaultSalt];
}


+(NSData*) deriveKeyFromMaterial:(NSData *)input outputLength:(NSUInteger)outputLength info:(NSData *)info salt:(NSData *)salt {
    char prk[HKDF_HASH_LEN] = {0};
    char *okm = NULL;
    
    if ((!input) || (!info) || (!salt)) {
        @throw [NSException exceptionWithName:@"Invalid argument" reason:@"A supplied argument was nil" userInfo:nil];
    }
    
    if (ceil((float)outputLength/HKDF_HASH_LEN) > 255) {
        @throw [NSException exceptionWithName:@"Invalid output length" reason:@"The supplied output length is larger than the max HKDF output length" userInfo:nil];
    }
    
    // Step 1 - Extract
    [TSHKDF extract:[input bytes] ikmLength:[input length] salt:[salt bytes] saltLength:[salt length] prkOut:prk];
    
    // Step 2 - Expand
    okm = malloc(outputLength); // automatically freed by NSData
    if (!okm) {
        @throw [NSException exceptionWithName:@"malloc failed" reason:@"Could not allocate okm" userInfo:nil];
    }
    [TSHKDF expand:prk prkLength:sizeof(prk) info:[info bytes] infoLength:[info length] output:okm outputLength:outputLength];
    
    return [NSData dataWithBytesNoCopy:okm length:outputLength freeWhenDone:YES];
}


/* From RFC 5869:
 The output PRK is calculated as follows:
 
 PRK = HMAC-Hash(salt, IKM)
 */
+(void) extract:(const void *)ikm ikmLength:(size_t)ikmLength salt:(const void *)salt saltLength:(size_t)saltLength prkOut:(void *)prkOut {
    // The caller already checked that all arguments != NULL
    CCHmac(HKDF_HASH_ALG, salt, saltLength, ikm, ikmLength, prkOut);
}



/* From RFC 5869:
 The output OKM is calculated as follows:
 
 N = ceil(L/HashLen)
 T = T(1) | T(2) | T(3) | ... | T(N)
 OKM = first L octets of T
 
 where:
 T(0) = empty string (zero length)
 T(1) = HMAC-Hash(PRK, T(0) | info | 0x01)
 T(2) = HMAC-Hash(PRK, T(1) | info | 0x02)
 T(3) = HMAC-Hash(PRK, T(2) | info | 0x03)
 ...
 */
+(void) expand:(const void *)prk prkLength:(size_t)prkLength info:(const void *)info infoLength:(size_t)infoLength output:(void *)output outputLength:(size_t)outputLength {
    int i = 0;
    int N = 0;
    size_t TInputLength = 0;
    void *outputCurrentPosition = output;
    char *TiInput = NULL;
    char *TiOutput = NULL;
    
    
    TiInput = malloc(HKDF_HASH_LEN + infoLength + 1);
    if (!TiInput) {
        @throw [NSException exceptionWithName:@"malloc failed" reason:@"Could not allocate TiInput" userInfo:nil];
    }
    TiOutput = malloc(HKDF_HASH_LEN);
    if (!TiOutput) {
        free(TiInput);
        @throw [NSException exceptionWithName:@"malloc failed" reason:@"Could not allocate TiOutput" userInfo:nil];
    }
    
    // The caller already checked that all arguments != NULL
    
    // Compute N, the number of HMAC rounds; the caller already checked that N <= 255
    N = ceil((float)outputLength/HKDF_HASH_LEN); // TODO: try with 255
    
    // Generate input for T(1)
    memcpy(TiInput, info, infoLength);
    memset(TiInput + infoLength, (char)1, 1);
    TInputLength = infoLength + 1;

    
    // Compute T(i)
    for(i=1;i<=N;i++) {
        size_t lengthToCopy = 0;
        
        // Stop if we've generated enough bytes
        if (outputCurrentPosition == output+outputLength) {
            break;
        }
        
        // Compute T(i)
        CCHmac(HKDF_HASH_ALG, prk, prkLength, TiInput, TInputLength, TiOutput);

        // Store T(i)
        lengthToCopy = MIN(HKDF_HASH_LEN, output+outputLength-outputCurrentPosition);
        memcpy(outputCurrentPosition, TiOutput, lengthToCopy);
        outputCurrentPosition += lengthToCopy;
        
        // Generate input for T(i+1)
        memcpy(TiInput, TiOutput, HKDF_HASH_LEN);
        memcpy(TiInput + HKDF_HASH_LEN, info, infoLength);
        memset(TiInput + HKDF_HASH_LEN + infoLength, i+1, 1);
        TInputLength = HKDF_HASH_LEN + infoLength + 1;
    }
    
    free(TiInput);
    free(TiOutput);
}


@end
