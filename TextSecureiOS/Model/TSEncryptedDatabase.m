//
//  TSEncryptedDatabase.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSEncryptedDatabase.h"
#import "TSEncryptedDatabase+Private.h"
#import "TSEncryptedDatabaseError.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "ECKeyPair.h"
#import "FilePath.h"
#import "NSData+Base64.h"
#import "KeychainWrapper.h"
#import "TSKeyManager.h"



// Reference to the singleton
static TSEncryptedDatabase *SharedCryptographyDatabase = nil;


@implementation TSEncryptedDatabase {

    @protected FMDatabaseQueue *dbQueue;
}

#pragma mark Database instantiation

+(instancetype) database {
  if (!SharedCryptographyDatabase) {
     @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"database must be unlocked or created prior to being able to use this method" userInfo:nil];
  }
  return SharedCryptographyDatabase;
  
}


+(void) databaseErase {
    @synchronized(SharedCryptographyDatabase) {
        
        // Erase the DB file
        [[NSFileManager defaultManager] removeItemAtPath:[FilePath pathInDocumentsDirectory:databaseFileName] error:nil];
        
        // Erase the DB encryption key from the Keychain
        [TSKeyManager eraseDatabaseMasterKey];
        
        // Update the preferences
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:kDBWasCreatedBool];
        SharedCryptographyDatabase = nil;
    }
}


+(instancetype) databaseCreateWithPassword:(NSString *)userPassword error:(NSError **)error {

    // Have we created a DB on this device already ?
    if ([TSEncryptedDatabase databaseWasCreated]) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbAlreadyExists];
        }
        return nil;
    }
    
    // 1. Cleanup remnants of a previous DB
    [TSEncryptedDatabase databaseErase];

    // 2. Create the DB encryption key, the DB and the tables
    NSData *dbMasterKey = [TSKeyManager generateDatabaseMasterKeyWithPassword:userPassword];
    if (!dbMasterKey) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbCreationFailed];
        }
        return nil;
    }
    
    __block BOOL dbInitSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:databaseFileName]];
    [dbQueue inDatabase:^(FMDatabase *db) {
        
        if(![db setKeyWithData:dbMasterKey]) {
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE persistent_settings (setting_name TEXT UNIQUE,setting_value TEXT)"]) {
            // Happens when the master key is wrong (ie. wrong (old?) encrypted key in the keychain)
            return;
        }
        if (![db executeUpdate:@"CREATE TABLE personal_prekeys (prekey_id INTEGER UNIQUE,public_key TEXT,private_key TEXT, last_counter INTEGER)"]){
            return;
        }
        dbInitSuccess = YES;
    }
     ];
    
    if (!dbInitSuccess) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbCreationFailed];
        }
        // Cleanup
        [TSEncryptedDatabase databaseErase];
        return nil;
    }
    
    // We have now have an empty DB
    SharedCryptographyDatabase = [[TSEncryptedDatabase alloc] initWithDatabaseQueue:dbQueue];

    // 4. Success - store in the preferences that the DB has been successfully created
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kDBWasCreatedBool];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return SharedCryptographyDatabase;
}


-(BOOL) storePrekeys:(NSArray*)prekeyArray {
  for(ECKeyPair* keyPair in prekeyArray) {
    __block BOOL updateSuccess = NO;
    [self->dbQueue inDatabase:^(FMDatabase *db) {
      if ([db executeUpdate:@"INSERT OR REPLACE INTO personal_prekeys (prekey_id,public_key,private_key,last_counter) VALUES (?,?,?,?)",[NSNumber numberWithInt:[keyPair prekeyId]], [keyPair publicKey], [keyPair privateKey],[NSNumber numberWithInt:0]]) {
        updateSuccess = YES;
      }
    }];
    if (!updateSuccess) {
      return NO;
      //@throw [NSException exceptionWithName:@"DB creation error" reason:@"could not write prekey" userInfo:nil];
    }
  }
  return YES;
}

-(BOOL) storeIdentityKey:(ECKeyPair*)identityKey {
  __block BOOL updateSuccess = NO;
  [self->dbQueue inDatabase:^(FMDatabase *db) {
    
    if (![db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?, ?)",@"identity_key_private",[identityKey privateKey]]) {
      DLog(@"Error updating DB: %@", [db lastErrorMessage]);
      return;
    }
    
    if (![db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?, ?)",@"identity_key_public",[identityKey publicKey]]) {
      DLog(@"Error updating DB: %@", [db lastErrorMessage]);
      return;
    }
    updateSuccess = YES;
  }];
  return updateSuccess;
  
  
  
}

+(instancetype) databaseUnlockWithPassword:(NSString *)userPassword error:(NSError **)error {
    
    // DB is already unlocked
    if ((SharedCryptographyDatabase) && (![SharedCryptographyDatabase isLocked])) {
        return SharedCryptographyDatabase;
    }
    
    // Make sure a DB has already been created
    if (![TSEncryptedDatabase databaseWasCreated]) {
        if (error) {
            *error = [TSEncryptedDatabaseError noDbAvailable];
        }
        return nil;
    }
    
    // Get the DB master key
    NSData *key = [TSKeyManager getDatabaseMasterKeyWithPassword:userPassword error:error];
    if(key == nil) {
        return nil;
    }
    
    // Try to open the DB
    __block BOOL initSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:databaseFileName]];
    [dbQueue inDatabase:^(FMDatabase *db) {
        
        if(![db setKeyWithData:key]) {
            // Supplied password was valid but the master key wasn't !?
            return;
        }
        
        // Do a test query to make sure the DB is available
        FMResultSet *rset = [db executeQuery:@"SELECT * FROM persistent_settings"];
        if (rset) {
            [rset close];
            initSuccess = YES;
        }
    }];
    if (!initSuccess) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbWasCorrupted];
        }
        return nil;
    }
    
    // Initialize the DB singleton
    if (!SharedCryptographyDatabase) {
        // First time in the app's lifecycle we're unlocking the DB
        SharedCryptographyDatabase = [[TSEncryptedDatabase alloc] initWithDatabaseQueue:dbQueue];
    }
    else {
        // DB had already been instantiated but was locked
        SharedCryptographyDatabase->dbQueue = dbQueue;
    }
    
    return SharedCryptographyDatabase;
}


#pragma mark Database state

+(BOOL) databaseWasCreated {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDBWasCreatedBool];
}


+(void) databaseLock {
    
    if (!SharedCryptographyDatabase) {
        @throw [NSException exceptionWithName:@"DB lock failed" reason:@"tried to lock the DB before opening/unlocking it" userInfo:nil];
    }
    
    if ([SharedCryptographyDatabase isLocked]) {
        return;
    }
    
    @synchronized(SharedCryptographyDatabase->dbQueue) {
        // Synchronized in case some other code/thread still has a reference to the DB
        // TODO: Investigate whether this truly closes the DB (in memory)
        [SharedCryptographyDatabase->dbQueue close];
        SharedCryptographyDatabase->dbQueue = nil;
    }
}


-(BOOL) isLocked {
    if ((!SharedCryptographyDatabase) || (!SharedCryptographyDatabase->dbQueue) ) {
        return YES;
    }
    return NO;
}



#pragma mark Database initialization - private

-(instancetype) initWithDatabaseQueue:(FMDatabaseQueue *)queue {
    if (self = [super init]) {
        self->dbQueue = queue;
    }
    return self;
}




#pragma mark Database content

-(NSArray*) getPersonalPrekeys {
    
    // TODO: Error handling
    if ([SharedCryptographyDatabase isLocked]) {
        // TODO: Prompt the user for their password and call databaseUnlock first
        @throw [NSException exceptionWithName:@"DB is locked" reason:@"database must be unlocked or created prior to being able to use this method" userInfo:nil];
    }
    
  NSMutableArray *prekeyArray = [[NSMutableArray alloc] init];
  [self->dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM personal_prekeys"]];
    while([rs next]) {
      ECKeyPair *keyPair = [[ECKeyPair alloc] initWithPublicKey:[rs stringForColumn:@"public_key"]
                                                     privateKey:[rs stringForColumn:@"private_key"]
                                                       prekeyId:[rs intForColumn:@"prekey_id"]];
      [prekeyArray addObject:keyPair];
    }
  }];
  return prekeyArray;
}


-(ECKeyPair*) getIdentityKey {
    
    // TODO: Error handling
    
    if ([SharedCryptographyDatabase isLocked]) {
        // TODO: Prompt the user for their password and call databaseUnlock first
        @throw [NSException exceptionWithName:@"DB is locked" reason:@"database must be unlocked or created prior to being able to use this method" userInfo:nil];
    }
    
  __block NSString* identityKeyPrivate = nil;
  __block NSString* identityKeyPublic = nil;
  [self->dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT setting_value FROM persistent_settings WHERE setting_name=\"identity_key_public\""]];
    if([rs next]){
      identityKeyPublic = [rs stringForColumn:@"setting_value"];
    }
    [rs close];
    rs = [db executeQuery:[NSString stringWithFormat:@"SELECT setting_value FROM persistent_settings WHERE setting_name=\"identity_key_private\""]];

    if([rs next]){
      identityKeyPrivate = [rs stringForColumn:@"setting_value"];
    }
    [rs close];
  }];
  if(identityKeyPrivate==nil || identityKeyPublic==nil) {
    return nil;
  }
  else {
    return [[ECKeyPair alloc] initWithPublicKey:identityKeyPublic privateKey:identityKeyPrivate];
  }
}

@end
