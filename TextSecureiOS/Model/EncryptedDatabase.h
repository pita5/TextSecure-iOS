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
// Create a new one
+(instancetype) databaseCreateWithPassword:(NSString *)userPassword error:(NSError **)error;

// Open an existing one
+(instancetype) databaseUnlockWithPassword:(NSString *)userPassword error:(NSError **)error;

// Get a reference if it has already been created/opened; it might locked (ie. pw-protected) tho
+(instancetype) database;


+(void) databaseLock;  // TODO: Use this to lock (ie. pw-protect) the DB after X minutes
+(void) databaseErase;

+(BOOL) databaseWasCreated;

-(BOOL) isUnlocked;
-(ECKeyPair*) getIdentityKey;
-(NSArray*) getPersonalPrekeys;
@end
