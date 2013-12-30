//
//  TSEncryptedDatabase2.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class FMDatabaseQueue;


@interface TSEncryptedDatabase2 : NSObject

@property (nonatomic, retain) FMDatabaseQueue *dbQueue;


+(instancetype) databaseCreateAtFilePath:(NSString *)dbFilePath updateBoolPreference:(NSString *)preferenceName error:(NSError **)error;
+(instancetype) databaseOpenAndDecryptAtFilePath:(NSString *)dbFilePath error:(NSError **)error;
+(void) databaseEraseAtFilePath:(NSString *)dbFilePath updateBoolPreference:(NSString *)preferenceName;


@end
