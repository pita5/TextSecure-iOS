//
//  TSMessagesDatabase.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesDatabase.h"
#import "TSStorageError.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>

#import "FilePath.h"
#import "TSMessage.h"
#import "TSContact.h"
#import "TSThread.h"
#import "TSAttachment.h"
#import "TSStorageMasterKey.h"
#import "TSEncryptedDatabase.h"
#import "TSKeyManager.h"

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
        
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS threads (thread_id TEXT PRIMARY KEY, rk BLOB, cks BLOB, ckr BLOB, dhis BLOB, dhir BLOB, dhrs BLOB, dhrr BLOB, ns INT, nr INT, pns INT)"]) {
            return;
        }
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS missed_messages (skipped_MK BLOB,skipped_HKs BLOB, skipped_HKr BLOB,thread_id TEXT,FOREIGN KEY(thread_id) REFERENCES threads(thread_id))"]) {
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (message_id INT PRIMARY KEY,message TEXT,thread_id TEXT,sender_id TEXT,recipient_id TEXT, timestamp DATE,FOREIGN KEY(thread_id) REFERENCES threads(thread_id))"]) {
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS contacts (registered_phone_number TEXT,relay TEXT, useraddressbookid INTEGER, identitykey TEXT, identityverified INTEGER, supports_sms INTEGER, next_key TEXT)"]){
            return;
        }
        
        dbInitSuccess = YES;
        
    }];
    
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

+(void) storeMessage:(TSMessage*)message fromThread:(TSThread*) thread withCompletionBlock:(dataBaseUpdateCompletionBlock)block{
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]) {
            // TODO: better error handling
            return;
        }
    }
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        NSString *sqlDate = [dateFormatter stringFromDate:message.timestamp];
        [db executeUpdate:@"INSERT OR REPLACE INTO threads (thread_id) VALUES (?)",thread.threadID];
        [db executeUpdate:@"INSERT INTO messages (message,thread_id,sender_id,recipient_id,timestamp) VALUES (?, ?, ?, ?, ?)",message.content,thread.threadID,message.senderId,message.recipientId,sqlDate];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(TRUE);
        });
    }];
}

+(void) getMessagesOnThread:(TSThread*) thread withCompletion:(dataBaseFetchCompletionBlock) block {
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]){
            NSLog(@"The database is locked!");
            return;
        }
    }
    
    __block NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        FMResultSet  *searchInDB = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM messages WHERE thread_id=\"%@\" ORDER BY timestamp", [thread threadID]]];
        
        while([searchInDB next]) {
            NSString* timestamp = [searchInDB stringForColumn:@"timestamp"];
            NSDate *date = [dateFormatter dateFromString:timestamp];
            TSAttachment *attachment = nil;
            TSAttachmentType attachmentType = [searchInDB intForColumn:@"attachment_type"];
            if(attachmentType!=TSAttachmentEmpty) {
                NSString *attachmentDataPath = [searchInDB stringForColumn:@"attachment"];
                NSData *attachmentDecryptionKey = [searchInDB dataForColumn:@"attachment_decryption_key"];
                attachment = [[TSAttachment alloc] initWithAttachmentDataPath:attachmentDataPath withType:attachmentType withDecryptionKey:attachmentDecryptionKey];
            }
            [messageArray addObject:[TSMessage messageWithContent:[searchInDB stringForColumn:@"message"] sender:[searchInDB stringForColumn:@"sender_id"] recipient:[searchInDB stringForColumn:@"recipient_id"] date:date attachment:attachment]];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(messageArray);
        });
        
        [searchInDB close];
    }];
    
}

// This is only a temporary stub for fetching the message threads
// Temporarily fix is to make this blocking a blocking method

+(void) getThreadsWithCompletion:(dataBaseFetchCompletionBlock) block {
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]){
            DLog(@"The database is not open.");
            block(nil);
            return;
        }
        DLog(@"The messages database could not be found");
        return;
    }
    
    __block NSMutableArray *threadArray = [[NSMutableArray alloc] init];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        FMResultSet  *searchInDB = [db executeQuery:@"SELECT *,MAX(m.timestamp) FROM messages m GROUP BY thread_id ORDER BY timestamp DESC;"];
        
        while([searchInDB next]) {
            NSString* timestamp = [searchInDB stringForColumn:@"timestamp"];
            NSDate *date = [dateFormatter dateFromString:timestamp];
            
            TSContact *contact;
            NSString *senderID = [searchInDB stringForColumn:@"sender_id"];
            NSString *receiverID = [searchInDB stringForColumn:@"recipient_id"];
            
            NSString *userID = [TSKeyManager getUsernameToken];
            if ([userID isEqualToString:[searchInDB stringForColumn:@"recipient_id"]]) {
                contact = [[TSContact alloc] initWithRegisteredID:senderID];
            }
            else {
                contact = [[TSContact alloc] initWithRegisteredID:receiverID];
            }
            
            TSContact *sender = [[TSContact alloc] initWithRegisteredID:[searchInDB stringForColumn:@"sender_id"]];
            TSContact *receiver = [[TSContact alloc] initWithRegisteredID:[searchInDB stringForColumn:@"recipient_id"]];
            TSThread *messageThread = [TSThread threadWithContacts:@[contact]];
            
            NSLog(@"Thread ID when retreived %@", messageThread.threadID);
            
            TSAttachment *attachment = nil;
            TSAttachmentType attachmentType = [searchInDB intForColumn:@"attachment_type"];
            if(attachmentType!=TSAttachmentEmpty) {
                NSString *attachmentDataPath = [searchInDB stringForColumn:@"attachment"];
                NSData *attachmentDecryptionKey = [searchInDB dataForColumn:@"attachment_decryption_key"];
                attachment = [[TSAttachment alloc] initWithAttachmentDataPath:attachmentDataPath withType:attachmentType withDecryptionKey:attachmentDecryptionKey];
            }
            
            messageThread.latestMessage = [TSMessage messageWithContent:[searchInDB stringForColumn:@"message"] sender:sender.registeredID recipient:receiver.registeredID date:date attachment:nil];
            
            [threadArray addObject:messageThread];
        }
        
        block(threadArray);
        
        [searchInDB close];
    }];
}

+(void) storeTSThread:(TSThread*)thread withCompletionBlock:(dataBaseUpdateCompletionBlock)block{
    
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

+(void) deleteTSThread:(TSThread*)thread withCompletionBlock:(dataBaseUpdateCompletionBlock) block {
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM messages WHERE thread_id=:threadID" withParameterDictionary:@{@"threadID": thread.threadID}];
        [db executeUpdate:@"DELETE FROM threads WHERE thread_id=:threadID" withParameterDictionary:@{@"threadID": thread.threadID}];
        block(TRUE);
    }];
}

+(void) findTSContactForPhoneNumber:(NSString*)phoneNumber{
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return;
    }
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *searchInDB = [db executeQuery:@"SELECT registeredID FROM contacts WHERE registered_phone_number = :phoneNumber " withParameterDictionary:@{@"phoneNumber":phoneNumber}];
        
        if ([searchInDB next]) {
            // That was found :)
            NSLog(@"Entry %@", [searchInDB stringForColumn:@"useraddressbookid"]);
        }
        
        [searchInDB close];
    }];
}

+(void)storeTSContact:(TSContact*)contact withCompletionBlock:(dataBaseUpdateCompletionBlock)block{
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil])
            // TODO: better error handling
            return;
    }
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *searchInDB = [db executeQuery:@"SELECT registeredID FROM contacts WHERE registered_phone_number = :phoneNumber " withParameterDictionary:@{@"phoneNumber":contact.registeredID}];
        NSDictionary *parameterDictionary = @{@"registeredID": contact.registeredID, @"relay": contact.relay, @"userABID": contact.userABID, @"identityKey": contact.identityKey, @"identityKeyIsVerified":[NSNumber numberWithInt:((contact.identityKeyIsVerified)?1:0)], @"supportsSMS":[NSNumber numberWithInt:((contact.supportsSMS)?1:0)], @"nextKey":contact.nextKey};
        
        
        if ([searchInDB next]) {
            // the phone number was found, let's now update the contact
            [db executeUpdate:@"UPDATE contacts SET relay = :relay, useraddressbookid :userABID, identitykey = :identityKey, identityverified = :identityKeyIsVerified, supports_sms = :supportsSMS, next_key = :nextKey WHERE registered_phone_number = :registeredID" withParameterDictionary:parameterDictionary];
        }
        else{
            // the contact doesn't exist, let's create him
            [db executeUpdate:@"REPLACE INTO contacts (:registeredID,:relay , :userABID, :identityKey, :identityKeyIsVerified, :supportsSMS, :nextKey)" withParameterDictionary:parameterDictionary];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(TRUE);
        });
        
        [searchInDB close];
    }];
    
}

#pragma mark - AxolotlPersistantStorage protocol getter/setter helper methods

+(void) getAPSDataField:(NSString*)name onThread:(TSThread*)thread withCompletion:(dataBaseFetchDataCompletionBlock)block{
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]) {
            // TODO: better error handling
            return;
        }
    }
    __block NSData* apsField = nil;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"threadID":thread.threadID}];
        if ([searchInDB next]) {
            apsField= [searchInDB dataForColumn:name];
        }
        [searchInDB close];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(apsField);
        });
    }];
}


+(void) getAPSIntField:(NSString*)name onThread:(TSThread*)thread withCompletion:(dataBaseFetchIntCompletionBlock)block {
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]) {
            block(nil);
            return;
        }
        return;
    }
    __block NSNumber* apsField = 0;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"threadID":thread.threadID}];
        if ([searchInDB next]) {
            apsField = [NSNumber numberWithInt:[searchInDB intForColumn:name]];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(apsField);
        });
        [searchInDB close];
    }];
}

+(void) getAPSBoolField:(NSString*)name onThread:(TSThread*)thread withCompletion:(dataBaseFetchBOOLCompletionBlock)block {
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]) {
            
            return;
        }
        return;
    }
    __block int apsField = 0;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"threadID":thread.threadID}];
        if ([searchInDB next]) {
            apsField= [searchInDB boolForColumn:name];
        }
        [searchInDB close];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(apsField);
        });
    }];
}

+(void) getAPSStringField:(NSString*)name onThread:(TSThread*)thread withCompletion:(dataBaseFetchStringCompletionBlock)block{
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]) {
            // TODO: better error handling
            return;
        }
        return;
    }
    __block NSString* apsField = 0;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"threadID":thread.threadID}];
        if ([searchInDB next]) {
            apsField= [searchInDB stringForColumn:name];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(apsField);
        });
        [searchInDB close];
    }];
}



+(void) setAPSDataField:(NSDictionary*) parameters withCompletion:(dataBaseUpdateCompletionBlock)block{
    /*
     parameters
     nameField : name of db field to set
     valueField : value of db field to set to
     threadID" : thread id
     */
    
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]){
            DLog(@"Database is not open");
            return;
        }
        DLog(@"No Database found");
        return;
        
    }
    
    if (!([parameters count] == 3)) {
        DLog(@"Not all parameters were set! ==>  %@", parameters);
    }
    
    NSString* query = [NSString stringWithFormat:@"INSERT OR REPLACE INTO threads (thread_id,%@) VALUES (?,?)",[parameters objectForKey:@"nameField"]];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:query withArgumentsInArray:@[[parameters objectForKey:@"threadID"], [parameters objectForKey:@"valueField"]]];
        NSLog(@"Query executed");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"Executing callback");
            block(TRUE);
        });
    }];
    
}

+(NSString*) getAPSFieldName:(NSString*)name onChain:(TSChainType)chain{
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
+(void) getRK:(TSThread*)thread withCompletionBlock:(keyStoreFetchDataCompletionBlock)block {
    [TSMessagesDatabase getAPSDataField:@"rk"  onThread:thread withCompletion:block];
}


+(void) setRK:(NSData*)key onThread:(TSThread*)thread withCompletionBlock:(keyStoreSetDataCompletionBlock)block{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":@"rk",@"valueField":key,@"threadID":thread.threadID} withCompletion:block];
}
/* Chain keys */
+(void) getCK:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreFetchDataCompletionBlock)block{
    [TSMessagesDatabase getAPSDataField:[TSMessagesDatabase getAPSFieldName:@"ck" onChain:chain] onThread:thread withCompletion:block];
    
}
+(void) setCK:(NSData*)key onThread:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreSetDataCompletionBlock)block{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase getAPSFieldName:@"ck" onChain:chain],@"valueField":key,@"threadID":thread.threadID} withCompletion:block];
}

/* ephemeral keys of chains */
+(void) getEphemeralOfReceivingChain:(TSThread*)thread withCompletionBlock:(keyStoreFetchDataCompletionBlock)block{
    return [TSMessagesDatabase getAPSDataField:[TSMessagesDatabase getAPSFieldName:@"dhr" onChain:TSReceivingChain ] onThread:thread withCompletion:block];
}

+(void) setEphemeralOfReceivingChain:(NSData*)key onThread:(TSThread*)thread withCompletionBlock:(keyStoreSetDataCompletionBlock)block{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase getAPSFieldName:@"dhr" onChain:TSReceivingChain],@"valueField":key,@"threadID":thread.threadID}withCompletion:block];
}

+(void) getEphemeralOfSendingChain:(TSThread*)thread withCompletionBlock:(keyStoreFetchKeyPairCompletionBlock)block{
    [TSMessagesDatabase getAPSDataField:[TSMessagesDatabase getAPSFieldName:@"dhr" onChain:TSSendingChain ] onThread:thread withCompletion:^(NSData *data) {
        block([NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedUnarchiver unarchiveObjectWithData:data]]);
    }];
}

+(void) setEphemeralOfSendingChain:(TSECKeyPair*)key onThread:(TSThread*)thread withCompletionBlock:(keyStoreSetDataCompletionBlock)block{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase getAPSFieldName:@"dhr" onChain:TSSendingChain],@"valueField":[NSKeyedArchiver archivedDataWithRootObject:key],@"threadID":thread.threadID} withCompletion:block];
}


/* number of messages sent on chains */
+(void) getN:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreFetchNumberCompletionBlock)block{
    [TSMessagesDatabase getAPSIntField:[TSMessagesDatabase getAPSFieldName:@"n" onChain:chain] onThread:thread withCompletion:block];
    
}
+(void) setN:(NSNumber*)num onThread:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreSetDataCompletionBlock)block{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase getAPSFieldName:@"n" onChain:chain],@"valueField":num,@"threadID":thread.threadID} withCompletion:block];
}

/* number of messages sent on the last chain */
+(void)getPNs:(TSThread*)thread withCompletionBlock:(keyStoreFetchNumberCompletionBlock)block{
    [TSMessagesDatabase getAPSIntField:@"pns" onThread:thread withCompletion:block];
}
+(void)setPNs:(NSNumber*)num onThread:(TSThread*)thread withCompletionBlock:(keyStoreSetDataCompletionBlock)block{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":@"pns",@"valueField":num,@"threadID":thread.threadID} withCompletion:block];
}

//Ns, Nr       : sets N to N+1 returns value of N prior to setting,  Message numbers (reset to 0 with each new ratchet)
+(void) getNPlusPlus:(TSThread*)thread onChain:(TSChainType)chain withCompletionBlock:(keyStoreFetchNumberCompletionBlock)block{
    [TSMessagesDatabase getN:thread onChain:chain withCompletionBlock:^(NSNumber *number) {
        [TSMessagesDatabase setN:[NSNumber numberWithInt:[number integerValue]+1] onThread:thread onChain:chain withCompletionBlock:^(BOOL success) {
            if (success) {
                block(number);
            }
        }];
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
