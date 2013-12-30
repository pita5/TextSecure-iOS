//
//  TSMessagesDatabase.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesDatabase.h"
//#import "TSEncryptedDatabase+Private.h"
#import "TSEncryptedDatabaseError.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FilePath.h"
#import "TSMessage.h"
#import "TSContact.h"
#import "TSThread.h"
#import "TSStorageMasterKey.h"
#import "TSEncryptedDatabase2.h"


#define kDBWasCreatedBool @"TSMessagesWasCreated"
#define databaseFileName @"TSMessages.db"


NSString * const TSDatabaseDidUpdateNotification = @"com.whispersystems.database.update";


// Reference to the singleton
static TSEncryptedDatabase2 *messagesDb = nil;


@interface TSMessagesDatabase(Private)

+(BOOL) databaseOpenWithError:(NSError **)error;

@end


@implementation TSMessagesDatabase {

    @protected FMDatabaseQueue *dbQueue;
}

#pragma mark DB creation

+(BOOL) databaseCreateWithError:(NSError **)error {
    
    // Create the database
    TSEncryptedDatabase2 *db = [TSEncryptedDatabase2  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:databaseFileName] updateBoolPreference:kDBWasCreatedBool error:error];
    if (!db) {
        return NO;
    }
    
    
    // Create the tables we need
    __block BOOL dbInitSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:databaseFileName]];
    [dbQueue inDatabase:^(FMDatabase *db) {
        if (![db executeUpdate:@"CREATE TABLE persistent_settings (setting_name TEXT UNIQUE,setting_value TEXT)"]) {
            // Happens when the master key is wrong (ie. wrong (old?) encrypted key in the keychain)
            return;
        }
        if (![db executeUpdate:@"CREATE TABLE personal_prekeys (prekey_id INTEGER UNIQUE,public_key TEXT,private_key TEXT, last_counter INTEGER)"]){
            return;
        }
#warning we will want a subtler format than this, prototype message db format
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (thread_id INTEGER,message TEXT,sender_id TEXT,recipient_id TEXT, timestamp DATE)"]) {
            return;
        }
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS contacts (registered_phone_number TEXT,relay TEXT, useraddressbookid INTEGER, identitykey TEXT, identityverified INTEGER, supports_sms INTEGER, next_key TEXT)"]){
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
        [TSMessagesDatabase databaseErase];
        return NO;
    }

    
    return YES;
}


+(void) databaseErase {
    [TSEncryptedDatabase2 databaseEraseAtFilePath:[FilePath pathInDocumentsDirectory:databaseFileName] updateBoolPreference:kDBWasCreatedBool];
}


+(BOOL) databaseOpenWithError:(NSError **)error {
    
    // DB was already unlocked
    if (messagesDb){
        return YES;
    }
    
    TSEncryptedDatabase2 *db = [TSEncryptedDatabase2 databaseOpenAndDecryptAtFilePath:[FilePath pathInDocumentsDirectory:databaseFileName] error:error];
    if (!db) {
        return NO;
    }
    messagesDb = db;
    return YES;
}


+(BOOL) storePersistentSettings:(NSDictionary*)settingNamesAndValues {
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return NO;
    }
    
    __block BOOL updateSuccess = YES;
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    for(id settingName in settingNamesAndValues) {
      if (![db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?, ?)",settingName,[settingNamesAndValues objectForKey:settingName]]) {
        DLog(@"Error updating DB: %@", [db lastErrorMessage]);
        updateSuccess = NO;
      }
    }
  }];
  return updateSuccess;
}


#pragma mark Database state

+(BOOL) databaseWasCreated {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDBWasCreatedBool];
}


#pragma mark - DB message methods

+(void) storeMessage:(TSMessage*)message {

    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return;
    }
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        NSString *sqlDate = [dateFormatter stringFromDate:message.messageTimestamp];
        
#warning every message is on the same thread! also we only support one recipient
        [db executeUpdate:@"INSERT OR REPLACE INTO messages (thread_id,message,sender_id,recipient_id,timestamp) VALUES (?, ?, ?, ?, ?)",[NSNumber numberWithInt:0],message.message,message.senderId,message.recipientId,sqlDate];
    }];
}

+(NSArray*) getMessagesOnThread:(NSInteger) threadId {
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return nil;
    }
    
    __block NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM messages WHERE thread_id=%d ORDER BY timestamp", threadId]];

        while([rs next]) {
            NSString* timestamp = [rs stringForColumn:@"timestamp"];
            NSDate *date = [dateFormatter dateFromString:timestamp];
            
            [messageArray addObject:[[TSMessage alloc] initWithMessage:[rs stringForColumn:@"message"] sender:[rs stringForColumn:@"sender_id"] recipients:@[[rs stringForColumn:@"recipient_id"]] sentOnDate:date]];
        }
    }];
    
    return messageArray;
}

// This is only a temporary stub for fetching the message threads
// TODO: return the threads containing participants as well
+(NSArray *) getThreads {
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return nil;
    }
    
    __block NSMutableArray *threadArray = [[NSMutableArray alloc] init];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        FMResultSet  *rs = [db executeQuery:@"SELECT *,MAX(m.timestamp) FROM messages m GROUP BY thread_id ORDER BY timestamp DESC;"];
        
        while([rs next]) {
            NSString* timestamp = [rs stringForColumn:@"timestamp"];
            NSDate *date = [dateFormatter dateFromString:timestamp];
            
            TSThread *messageThread = [[TSThread alloc] init];
            messageThread.latestMessage = [[TSMessage alloc] initWithMessage:[rs stringForColumn:@"message"] sender:[rs stringForColumn:@"sender_id"] recipients:@[[rs stringForColumn:@"recipient_id"]] sentOnDate:date];
            
            [threadArray addObject:messageThread];
        }
    }];

    return threadArray;
}

+(void)storeTSThread:(TSThread*)thread {

    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return;
    }
    
    
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    for(TSContact* contact in thread.participants) {
      [contact save];
    }
  }];
}

+(void)findTSContactForPhoneNumber:(NSString*)phoneNumber{
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return;
    }
    
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    
    FMResultSet *searchIfExitInDB = [db executeQuery:@"SELECT registeredID FROM contacts WHERE registered_phone_number = :phoneNumber " withParameterDictionary:@{@"phoneNumber":phoneNumber}];
    
    if ([searchIfExitInDB next]) {
      // That was found :)
      NSLog(@"Entry %@", [searchIfExitInDB stringForColumn:@"useraddressbookid"]);
    }
    
    [searchIfExitInDB close];
  }];
}

+(void)storeTSContact:(TSContact*)contact{

    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return;
    }
    
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    
    FMResultSet *searchIfExitInDB = [db executeQuery:@"SELECT registeredID FROM contacts WHERE registered_phone_number = :phoneNumber " withParameterDictionary:@{@"phoneNumber":contact.registeredID}];
      NSDictionary *parameterDictionary = @{@"registeredID": contact.registeredID, @"relay": contact.relay, @"userABID": contact.userABID, @"identityKey": contact.identityKey, @"identityKeyIsVerified":[NSNumber numberWithInt:((contact.identityKeyIsVerified)?1:0)], @"supportsSMS":[NSNumber numberWithInt:((contact.supportsSMS)?1:0)], @"nextKey":contact.nextKey};
      
    
    if ([searchIfExitInDB next]) {
      // the phone number was found, let's now update the contact
      [db executeUpdate:@"UPDATE contacts SET relay = :relay, useraddressbookid :userABID, identitykey = :identityKey, identityverified = :identityKeyIsVerified, supports_sms = :supportsSMS, next_key = :nextKey WHERE registered_phone_number = :registeredID" withParameterDictionary:parameterDictionary];
    }
    else{
      // the contact doesn't exist, let's create him
      [db executeUpdate:@"REPLACE INTO contacts (:registeredID,:relay , :userABID, :identityKey, :identityKeyIsVerified, :supportsSMS, :nextKey)" withParameterDictionary:parameterDictionary];
    }
  }];
}


#pragma mark - shared private objects

+ (NSDateFormatter *)sharedDateFormatter {
    static NSDateFormatter *_sharedFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedFormatter = [[NSDateFormatter alloc] init];
        _sharedFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        _sharedFormatter.timeZone = [NSTimeZone localTimeZone];
    });
    
    return _sharedFormatter;
}

@end
