//
//  TSEncryptedDatabase2.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSEncryptedDatabase2.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "TSEncryptedDatabaseError.h"
#import "TSStorageMasterKey.h"



@implementation TSEncryptedDatabase2 {
}


+(instancetype) databaseCreateAtFilePath:(NSString *)dbFilePath updateBoolPreference:(NSString *)preferenceName error:(NSError **)error {
    
    // Have we created a DB on this device already ?
    if ([[NSUserDefaults standardUserDefaults] boolForKey:preferenceName]) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbAlreadyExists];
        }
        return nil;
    }
    
    // Cleanup remnants of a previous DB
    [TSEncryptedDatabase2 databaseEraseAtFilePath:dbFilePath updateBoolPreference:preferenceName];
    
    // Retrieve storage master key
    NSData *dbMasterKey = [TSStorageMasterKey getStorageMasterKeyWithError:error];
    if (!dbMasterKey) {
        return nil;
    }
    
    // Create the DB
    __block BOOL dbInitSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbFilePath];
    [dbQueue inDatabase:^(FMDatabase *db) {
        if(![db setKeyWithData:dbMasterKey]) {
            return;
        }

        FMResultSet *rset = [db executeQuery:@"SELECT count(*) FROM sqlite_master"];
        if (rset) {
            [rset close];
            dbInitSuccess = YES;
            return;
        }
    }];
    
    if (!dbInitSuccess) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbCreationFailed];
        }
        // Cleanup
        [TSEncryptedDatabase2 databaseEraseAtFilePath:dbFilePath updateBoolPreference:preferenceName];
        return nil;
    }
    
    TSEncryptedDatabase2 *encryptedDB = [[TSEncryptedDatabase2 alloc] initWithDatabaseFilePath:dbFilePath];
    
    // Success - store in the preferences that the DB has been successfully created
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:preferenceName];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return encryptedDB;
}


+(instancetype) databaseOpenAndDecryptAtFilePath:(NSString *)dbFilePath error:(NSError **)error {
    
    // Get the storage master key
    NSData *key = [TSStorageMasterKey getStorageMasterKeyWithError:error];
    if (!key) {
        return nil;
    }
    
    // Try to open the DB
    __block BOOL initSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbFilePath];
    
    [dbQueue inDatabase:^(FMDatabase *db) {
        if(![db setKeyWithData:key]) {
            // Supplied password was valid but the master key wasn't
            return;
        }
        // Do a test query to make sure the DB is available
        // if this throws an error, the key was incorrect. If it succeeds and returns a numeric value, the key is correct;
        FMResultSet *rset = [db executeQuery:@"SELECT count(*) FROM sqlite_master"];
        if (rset) {
            [rset close];
            initSuccess = YES;
            return;
        }}];
    
    if (!initSuccess) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbWasCorrupted];
        }
        return nil;
    }
    
    TSEncryptedDatabase2 *encryptedDB = [[TSEncryptedDatabase2 alloc] initWithDatabaseFilePath:dbFilePath];
    return encryptedDB;
}


+(void) databaseEraseAtFilePath:(NSString *)dbFilePath updateBoolPreference:(NSString *)preferenceName {
    // Update the preferences
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:preferenceName];
    
    // Erase the DB file
    [[NSFileManager defaultManager] removeItemAtPath:dbFilePath error:nil];
}


-(instancetype) initWithDatabaseFilePath:(NSString *)dbFilePath {
    if(self=[super init]) {
        self.dbFilePath = dbFilePath;
    }
    return self;
}


-(BOOL) queryWithBlock:(void (^)(FMDatabase *db) ) queryBlock error:(NSError **)error {
 
    // Get the storage master key
    NSData *key = [TSStorageMasterKey getStorageMasterKeyWithError:error];
    if (!key) {
        return NO;
    }
        
    // Try to open the DB
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:self.dbFilePath];
    if (!dbQueue) {
        if (error){
            *error = [TSEncryptedDatabaseError dbWasCorrupted];
        }
        return NO;
    }
    
    [dbQueue inDatabase:queryBlock];
    return YES;
}


@end
