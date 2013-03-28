//
//  Cryptography.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cryptography : NSObject
+(NSString*) generateAndStoreNewAccountAuthenticationToken;
+ (BOOL) storeAuthenticationToken:(NSString*)token;
+ (NSString*) getAuthenticationToken;
+ (BOOL) storeUsernameToken:(NSString*)token;
+ (NSString*) getUsernameToken;
+ (NSString*)computeSHA1DigestForString:(NSString*)input;
+ (void) generateECKeyPairSecurityFramework; // not used
+ (void) generateNISTp256ECCKeyPair;
+(void) testEncryption;
+ (NSString*) getAuthorizationToken;
@end
