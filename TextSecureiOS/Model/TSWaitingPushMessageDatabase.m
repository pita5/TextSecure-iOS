//
//  TSWaitingPushMessageDatabase.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSWaitingPushMessageDatabase.h"
#import "TSEncryptedDatabase.h"
#import "TSStorageError.h"
#import "FilePath.h"
#import "Cryptography.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

static TSEncryptedDatabase *waitingPushMessageDb = nil;
NSString * const TSDatabaseDidUnlockNotification = @"com.whispersystems.database.unlocked";


@interface TSWaitingPushMessageDatabase(Private)

+(BOOL) databaseOpenWithError:(NSError **)error;

@end

@implementation TSWaitingPushMessageDatabase

#pragma mark DB creation

+(BOOL) databaseCreateWaitingPushMessageDatabaseWithError:(NSError **)error {
    // This DB is not required to be encrypted-the Push message content comes in pre-encrypted with the signaling key, and inside contents with the Axolotl ratchet
    // For very limited obfuscation of meta-data (unread message count), and to reuse the encrypted DB architecture we encrypt the entire DB itself with a key stored in user preferences.
    // The key cannot be stored somewhere accessible by password as this is designed to be deployed in the situation before the user enters her password.
    NSData* waitingPushMessagePassword = [ Cryptography generateRandomBytes:32];
    TSEncryptedDatabase *db = [TSEncryptedDatabase  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:WAITING_PUSH_MESSAGE_DB_FILE_NAME] updateBoolPreference:WAITING_PUSH_MESSAGE_DB_PREFERENCE withPassword:waitingPushMessagePassword error:error];
    if (!db) {
        return NO;
    }
    else {
        [[NSUserDefaults standardUserDefaults] setObject:waitingPushMessagePassword forKey:WAITING_PUSH_MESSAGE_DB_PASSWORD];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
    // Create the tables we need
    waitingPushMessageDb = db;
    __block BOOL querySuccess = NO;
    [waitingPushMessageDb.dbQueue inDatabase: ^(FMDatabase *db) {
        
        if (![db executeUpdate:@"CREATE TABLE push_messages (message_serialized_json BLOB,timestamp DATE)"]) {
            return;
        }
        querySuccess = YES;
    }];
    if (!querySuccess) {
        if (error) {
            *error = [TSStorageError errorDatabaseCreationFailed];
        }
        // Cleanup
        [TSWaitingPushMessageDatabase databaseErase];
        waitingPushMessageDb = nil;
        return NO;
    }
    
    
    return YES;
}


+(void) databaseErase {
    [TSEncryptedDatabase databaseEraseAtFilePath:[FilePath pathInDocumentsDirectory:WAITING_PUSH_MESSAGE_DB_FILE_NAME] updateBoolPreference:WAITING_PUSH_MESSAGE_DB_PREFERENCE];
    [[NSUserDefaults standardUserDefaults] setObject:FALSE forKey:WAITING_PUSH_MESSAGE_DB_PASSWORD];
}


+(BOOL) databaseWasCreated {
    return [[NSUserDefaults standardUserDefaults] boolForKey:WAITING_PUSH_MESSAGE_DB_PREFERENCE];
}



+(void) storePush:(NSDictionary*)pushMessageJson {
    // Decrypt the DB if it hasn't been done yet
    if (!waitingPushMessageDb) {
        if (![TSWaitingPushMessageDatabase databaseOpenWithError:nil]) {
            return;
        }
    }
    [waitingPushMessageDb.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO push_messages (message_serialized_json,timestamp) VALUES (?, CURRENT_TIMESTAMP)",[NSJSONSerialization dataWithJSONObject:pushMessageJson options:kNilOptions error:nil]];
    }];
}


+(NSArray*) getPushesInReceiptOrder {

    
    // Decrypt the DB if it hasn't been done yet
    if (!waitingPushMessageDb) {
        if (![TSWaitingPushMessageDatabase databaseOpenWithError:nil]){
            NSLog(@"The database is locked!");
        }
        return nil;
    }
    
    __block NSMutableArray *pushArray = [[NSMutableArray alloc] init];
    
    [waitingPushMessageDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet  *searchInDB = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM push_messages ORDER BY timestamp ASC"]];
        while([searchInDB next]) {
            [pushArray addObject:[NSJSONSerialization JSONObjectWithData:[searchInDB dataForColumn:@"message_serialized_json"] options:kNilOptions error:nil]];
        }
        [searchInDB close];
    }];
    
    return pushArray;
    
}


#pragma mark DB access - private

+(BOOL) databaseOpenWithError:(NSError **)error {
    
    // DB was already unlocked
    if (waitingPushMessageDb){
        return YES;
    }
    
    if (![TSWaitingPushMessageDatabase databaseWasCreated]) {
        if (error) {
            *error = [TSStorageError errorDatabaseNotCreated];
        }
        return NO;
    }
    NSData* storageKey = [[NSUserDefaults standardUserDefaults] objectForKey:WAITING_PUSH_MESSAGE_DB_PASSWORD];
    if(!storageKey) {
        return NO;
    }
    // We'll also want a "withPassword" here
    TSEncryptedDatabase *db = [TSEncryptedDatabase databaseOpenAndDecryptAtFilePath:[FilePath pathInDocumentsDirectory:WAITING_PUSH_MESSAGE_DB_FILE_NAME] withPassword:storageKey error:error];
    if (!db) {
        return NO;
    }
    waitingPushMessageDb = db;
    return YES;
}


@end
