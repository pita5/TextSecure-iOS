//
//  TSHKDF.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/7/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSHKDF : NSObject

+(NSData*) deriveKeyFromMaterial:(NSData *)input outputLength:(NSUInteger)outputLength info:(NSString *)info;
+(NSData*) deriveKeyFromMaterial:(NSData *)input outputLength:(NSUInteger)outputLength info:(NSString *)info salt:(NSData *)salt;

@end
