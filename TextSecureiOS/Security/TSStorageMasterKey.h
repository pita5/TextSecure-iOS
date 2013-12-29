//
//  TSStorageMasterKey.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSStorageMasterKey : NSObject


+(NSData*) createStorageMasterKeyWithPassword:(NSString *)userPassword;

+(NSData*) unlockStorageMasterKeyUsingPassword:(NSString *)userPassword error:(NSError **)error;
+(NSData*) getStorageMasterKeyWithError:(NSError **)error;

+(void) lockStorageMasterKey;
+(BOOL) isStorageMasterKeyLocked;

+(void) eraseStorageMasterKey;


@end
