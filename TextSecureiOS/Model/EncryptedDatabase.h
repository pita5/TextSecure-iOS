//
//  CryptographyDatabase.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECKeyPair;
@class FMDatabaseQueue;
@interface EncryptedDatabase : NSObject
@property (nonatomic,strong) FMDatabaseQueue *dbQueue;

// Three ways to get the shared encrypted DB:
+(instancetype) databaseCreateWithPassword:(NSString *)userPassword;
+(instancetype) databaseUnlockWithPassword:(NSString *)userPassword error:(NSError **)error;
// The last one can only be called after the DB has been created or unlocked
+(instancetype) database;

+(BOOL) dataBaseWasInitialized;
-(ECKeyPair*) getIdentityKey;
-(NSArray*) getPersonalPrekeys;
@end
