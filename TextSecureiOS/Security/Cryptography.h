//
//  Cryptography.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cryptography : NSObject
+(NSMutableData*) generateRandomBytes:(int)numberBytes;
#pragma mark SHA and HMAC methods
+(NSString*)truncatedSHA1Base64EncodedWithoutPadding:(NSString*)string;

+(NSData*) truncatedHMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey;

#pragma mark database key encryption/decryption
+(NSData*) getEncryptedDatabaseKey:(NSData*)decryptedDatabaseKey withPassword:(NSString*)userPassword error:(NSError**) error ;
+(NSData*) getDecryptedDatabaseKey:(NSString*)encryptedDatabaseKey withPassword:(NSString*)userPassword error:(NSError**) error ;


#pragma mark push payload encryption/decryption
+(NSData*) decryptPushPayload:(NSData*) dataToDecrypt withKey:(NSData*) key withIV:(NSData*) iv withVersion:(NSData*)version withHMACKey:(NSData*) HMACKey forHMAC:(NSData *)hmac;

+(NSData*)encryptPushPayload:(NSData*) dataToEncrypt withKey:(NSData*) key withIV:(NSData*) iv withVersion:(NSData*)version  withHMACKey:(NSData*) HMACKey computedHMAC:(NSData**)hmac;
@end
