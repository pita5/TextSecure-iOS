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
+(NSString*)truncatedSHA1Base64EncodedWithoutPadding:(NSString*)string;

@end
