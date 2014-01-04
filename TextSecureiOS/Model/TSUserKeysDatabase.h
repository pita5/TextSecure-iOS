//
//  TSUserKeysDatabase.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSECKeyPair;

@interface TSUserKeysDatabase : NSObject

+(BOOL) databaseCreateUserKeysWithError:(NSError **)error;
+(BOOL) databaseWasCreated;
+(void) databaseErase;

+(TSECKeyPair*) getIdentityKeyWithError:(NSError **)error;
+(NSArray*) getAllPreKeysWithError:(NSError **)error;
+(NSArray*) getPreKeyWithId:(int32_t)preKeyId error:(NSError **)error;

@end
