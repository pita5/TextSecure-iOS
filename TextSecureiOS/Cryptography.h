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

+ (NSString*) retrieveAuthenticationToken;
+ (NSString*)computeSHA1DigestForString:(NSString*)input;

+ (void) generateNISTp256ECCKeyPair;
@end
