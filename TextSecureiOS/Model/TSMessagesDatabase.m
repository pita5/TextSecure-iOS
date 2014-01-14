//
//  TSMessagesDatabase.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesDatabase.h"
#import "TSStorageError.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FilePath.h"
#import "TSMessage.h"
#import "TSContact.h"
#import "TSThread.h"
#import "TSStorageMasterKey.h"
#import "TSEncryptedDatabase.h"
#import "TSParticipants.h"


#define kDBWasCreatedBool @"TSMessagesWasCreated"
#define databaseFileName @"TSMessages.db"


NSString * const TSDatabaseDidUpdateNotification = @"com.whispersystems.database.update";


// Reference to the singleton
static TSEncryptedDatabase *messagesDb = nil;


@interface TSMessagesDatabase(Private)

+(BOOL) databaseOpenWithError:(NSError **)error;

@end


@implementation TSMessagesDatabase

#pragma mark DB creation

+(BOOL) databaseCreateWithError:(NSError **)error {
    
    // Create the database
    TSEncryptedDatabase *db = [TSEncryptedDatabase  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:databaseFileName] updateBoolPreference:kDBWasCreatedBool error:error];
    if (!db) {
        return NO;
    }
    
    
    // Create the tables we need
    __block BOOL dbInitSuccess = NO;
    [db.dbQueue inDatabase:^(FMDatabase *db) {
        if (![db executeUpdate:@"CREATE TABLE persistent_settings (setting_name TEXT UNIQUE,setting_value TEXT)"]) {
            // Happens when the master key is wrong (ie. wrong (old?) encrypted key in the keychain)
            return;
        }
        if (![db executeUpdate:@"CREATE TABLE personal_prekeys (prekey_id INTEGER UNIQUE,public_key TEXT,private_key TEXT, last_counter INTEGER)"]){
            return;
        }
#warning we will want a subtler format than this, prototype message db format
      /*
       RK           : 32-byte root key which gets updated by DH ratchet
       HKs, HKr     : 32-byte header keys (send and recv versions)
       NHKs, NHKr   : 32-byte next header keys (")
       CKs, CKr     : 32-byte chain keys (used for forward-secrecy updating)
       DHIs, DHIr   : DH or ECDH Identity keys
       DHRs, DHRr   : DH or ECDH Ratchet keys
       Ns, Nr       : Message numbers (reset to 0 with each new ratchet)
       PNs          : Previous message numbers (# of msgs sent under prev ratchet)
       ratchet_flag : True if the party will send a new DH ratchet key in next msg
       skipped_HK_MK : A list of stored message keys and their associated header keys
       for "skipped" messages, i.e. messages that have not been
       received despite the reception of more recent messages.
       Entries may be stored with a timestamp, and deleted after a
       certain age.
       */
      

      if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS threads (thread_id TEXT PRIMARY KEY, RK BLOB, HKs BLOB, HKr BLOB, NHKs BLOB, NHKr BLOB, CKs BLOB, CKr BLOB, DHIs BLOB, DHIr BLOB, DHRs BLOB, DHRr BLOB, Ns INT, Nr INT, PNs INT, ratchet_flag BOOL, skipped_HK_MK BLOB)"]) {
          return;
        }
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS missed_messages (skipped_MK BLOB,skipped_HKs BLOB, skipped_HKr BLOB,thread_id TEXT,FOREIGN KEY(thread_id) REFERENCES threads(thread_id))"]) {
          /*corresponds to skipped_HK_MK MK??*/
          return;
        }

        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (message_id INT PRIMARY KEY,message TEXT,thread_id TEXT,sender_id TEXT,recipient_id TEXT, timestamp DATE,FOREIGN KEY(thread_id) REFERENCES threads(thread_id))"]) {
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
            *error = [TSStorageError errorDatabaseCreationFailed];
        }
        // Cleanup
        [TSMessagesDatabase databaseErase];
        return NO;
    }

    messagesDb = db;
    return YES;
}


+(void) databaseErase {
    [TSEncryptedDatabase databaseEraseAtFilePath:[FilePath pathInDocumentsDirectory:databaseFileName] updateBoolPreference:kDBWasCreatedBool];
}


+(BOOL) databaseOpenWithError:(NSError **)error {
    
    // DB was already unlocked
    if (messagesDb){
        return YES;
    }

    if (![TSMessagesDatabase databaseWasCreated]) {
        if (error) {
            *error = [TSStorageError errorDatabaseNotCreated];
        }
        return NO;
    }

    messagesDb = [TSEncryptedDatabase databaseOpenAndDecryptAtFilePath:[FilePath pathInDocumentsDirectory:databaseFileName] error:error];
    if (!messagesDb) {
        return NO;
    }
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
      if (![TSMessagesDatabase databaseOpenWithError:nil]) {
            // TODO: better error handling
            return;
      }
    }
    
    TSContact *sender = [[TSContact alloc] initWithRegisteredID:message.senderId];
    TSContact *reciever = [[TSContact alloc] initWithRegisteredID:message.recipientId];
    NSString* threadId = [TSParticipants threadIDForParticipants:@[sender,reciever]];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        NSString *sqlDate = [dateFormatter stringFromDate:message.messageTimestamp];
        [db executeUpdate:@"INSERT OR REPLACE INTO threads (thread_id) VALUES (?)",threadId];
        [db executeUpdate:@"INSERT INTO messages (message,thread_id,sender_id,recipient_id,timestamp) VALUES (?, ?, ?, ?, ?)",message.message,threadId,message.senderId,message.recipientId,sqlDate];
    }];
}

+(NSArray*) getMessagesOnThread:(TSThread*) thread {
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return nil;
    }
    
    __block NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    // debug why this is returning me, and then you separately.
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM messages WHERE thread_id=\"%@\" ORDER BY timestamp", [thread threadID]]];

        while([rs next]) {
            NSString* timestamp = [rs stringForColumn:@"timestamp"];
            NSDate *date = [dateFormatter dateFromString:timestamp];
            [messageArray addObject:[[TSMessage alloc] initWithMessage:[rs stringForColumn:@"message"] sender:[rs stringForColumn:@"sender_id"] recipient:@[[rs stringForColumn:@"recipient_id"]] sentOnDate:date]];
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
            
            TSContact *sender = [[TSContact alloc] initWithRegisteredID:[rs stringForColumn:@"sender_id"]];
            TSContact *receiver = [[TSContact alloc] initWithRegisteredID:[rs stringForColumn:@"recipient_id"]];
            TSThread *messageThread = [TSThread threadWithParticipants:[[TSParticipants alloc] initWithTSContactsArray:@[sender,receiver]]];
            
            messageThread.latestMessage = [[TSMessage alloc] initWithMessage:[rs stringForColumn:@"message"] sender:sender.registeredID recipient:receiver.registeredID sentOnDate:date];

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
#warning thread.participants participants awkward, but TSParticipants being NSArray also awkward.
    for(TSContact* contact in [thread.participants participants]) {
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

#pragma mark - AxolotlPersistantStorage protocol getter/setter helper methods

+(NSData*) getAPSDataField:(NSString*)name onThread:(TSThread*)thread{
  if (!messagesDb) {
    if (![TSMessagesDatabase databaseOpenWithError:nil]) {
      // TODO: better error handling
      return nil;
    }
  }
  __block NSData* apsField = nil;
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    
    FMResultSet *rs = [db executeQuery:@"SELECT :fieldName FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"fieldName":name,@"threadID":thread.threadID}];
    if ([rs next]) {
      apsField= [rs dataForColumn:name];
    }
  }];
  return apsField;
}


+(NSNumber*) getAPSIntField:(NSString*)name onThread:(TSThread*)thread {
  if (!messagesDb) {
    if (![TSMessagesDatabase databaseOpenWithError:nil]) {
      // TODO: better error handling
      return 0;
    }
  }
  __block NSNumber* apsField = 0;
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    
    FMResultSet *rs = [db executeQuery:@"SELECT :fieldName FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"fieldName":name,@"threadID":thread.threadID}];
    if ([rs next]) {
      apsField= [NSNumber numberWithInt:[rs intForColumn:name]];
    }
  }];
  return apsField;

}

+(BOOL) getAPSBoolField:(NSString*)name onThread:(TSThread*)thread {
  if (!messagesDb) {
    if (![TSMessagesDatabase databaseOpenWithError:nil]) {
      // TODO: better error handling
      return 0;
    }
  }
  __block int apsField = 0;
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    
    FMResultSet *rs = [db executeQuery:@"SELECT :fieldName FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"fieldName":name,@"threadID":thread.threadID}];
    if ([rs next]) {
      apsField= [rs boolForColumn:name];
    }
  }];
  return apsField;
  
}

+(NSString*) getAPSStringField:(NSString*)name onThread:(TSThread*)thread {
  if (!messagesDb) {
    if (![TSMessagesDatabase databaseOpenWithError:nil]) {
      // TODO: better error handling
      return @"";
    }
  }
  __block NSString* apsField = 0;
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    
    FMResultSet *rs = [db executeQuery:@"SELECT :fieldName FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"fieldName":name,@"threadID":thread.threadID}];
    if ([rs next]) {
      apsField= [rs stringForColumn:name];
    }
  }];
  return apsField;
  
}

+(void) setAPSDataField:(NSDictionary*) parameters {
  /*
   parameters
   nameField : name of db field to set
   valueField : value of db field to set to
   threadID" : thread id
   */

  // Decrypt the DB if it hasn't been done yet
  if (!messagesDb) {
    if (![TSMessagesDatabase databaseOpenWithError:nil])
      // TODO: better error handling
      return;
  }
  
  [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
    
    [db executeQuery:@"UPDATE threads SET :nameField = :valueField where thread_id = :threadID" withParameterDictionary:parameters];
  }];

}

+(NSString*) getAPSFieldName:(NSString*)name onChain:(TSChainType)chain {
  switch (chain) {
    case TSReceivingChain:
      return [name stringByAppendingString:@"r"];
      break;
    case TSSendingChain:
      return [name stringByAppendingString:@"s"];
    default:
      return name;
      break;
  }
}


#pragma mark - AxolotlPersistantStorage protocol methods

/* Axolotl Protocol variables. Persistant storage per thread */
/* Root key*/
+(NSData*) getRK:(TSThread*)thread {
  return [TSMessagesDatabase getAPSDataField:@"RK"  onThread:thread];
}


+(void) setRK:(NSData*)key onThread:(TSThread*)thread {
  [TSMessagesDatabase setAPSDataField:@{@"nameField":@"RK",@"valueField":key,@"threadID":thread.threadID}];
}
/* Chain keys */
+(NSData*) getCK:(TSThread*)thread onChain:(TSChainType)chain{
  return [TSMessagesDatabase getAPSDataField:[TSMessagesDatabase getAPSFieldName:@"CK" onChain:chain] onThread:thread];

}
+(void) setCK:(NSData*)key onThread:(TSThread*)thread onChain:(TSChainType)chain{
  [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase getAPSFieldName:@"CK" onChain:chain],@"valueField":key,@"threadID":thread.threadID}];
}

/* ephemeral keys of chains */
+(NSData*) getEphemeralPublicKeyOfChain:(TSThread*)thread onChain:(TSChainType)chain{
  return [TSMessagesDatabase getAPSDataField:[TSMessagesDatabase getAPSFieldName:@"DHR" onChain:chain ] onThread:thread];
}

+(void) setEphemeralPublicKeyOfChain:(NSData*)key onThread:(TSThread*)thread onChain:(TSChainType)chain{
  [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase getAPSFieldName:@"DHR" onChain:chain],@"valueField":key,@"threadID":thread.threadID}];
}

/* number of messages sent on chains */
+(NSNumber*) getN:(TSThread*)thread onChain:(TSChainType)chain{
  return [TSMessagesDatabase getAPSIntField:[TSMessagesDatabase getAPSFieldName:@"N" onChain:chain] onThread:thread];
  
}
+(void) setN:(NSNumber*)num onThread:(TSThread*)thread onChain:(TSChainType)chain{
  [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase getAPSFieldName:@"N" onChain:chain],@"valueField":num,@"threadID":thread.threadID}];
}

/* number of messages sent on the last chain */
+(NSNumber*)getPNs:(TSThread*)thread{
  return [TSMessagesDatabase getAPSIntField:@"PNs" onThread:thread];
}
+(void)setPNs:(NSNumber*)num onThread:(TSThread*)thread{
  [TSMessagesDatabase setAPSDataField:@{@"nameField":@"PNs",@"valueField":num,@"threadID":thread.threadID}];
}

//Ns, Nr       : sets N to N+1 returns value of N prior to setting,  Message numbers (reset to 0 with each new ratchet)
+(NSNumber*) getNPlusPlus:(TSThread*)thread onChain:(TSChainType)chain {
  NSNumber* N = [TSMessagesDatabase getN:thread onChain:chain];
  
  [TSMessagesDatabase setN:[NSNumber numberWithInt:[N integerValue]+1] onThread:thread onChain:chain];
  return N;
  
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
