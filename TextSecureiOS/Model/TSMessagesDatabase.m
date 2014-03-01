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
#import "TSAttachment.h"
#import "TSStorageMasterKey.h"
#import "TSDatabaseManager.h"
#import "TSKeyManager.h"
#import "TSGroup.h"
#import "TSMessageIncoming.h"
#import "TSMessageOutgoing.h"
#import "TSConversation.h"
#import "TSSession.h"

#define kDBWasCreatedBool @"TSMessagesWasCreated"
#define databaseFileName @"TSMessages.db"

#define openDBMacroBOOL if (!messagesDb){if (![TSMessagesDatabase databaseOpenWithError:nil]) {return NO;}}
#define openDBMacroNil if (!messagesDb){if (![TSMessagesDatabase databaseOpenWithError:nil]) {return nil;}}

// Reference to the singleton
static TSDatabaseManager *messagesDb = nil;


@interface TSMessagesDatabase(Private)

+(BOOL) databaseOpenWithError:(NSError **)error;

@end

@implementation TSMessagesDatabase

#pragma mark DB creation

+ (NSString*)pathToDatabase{
    return [FilePath pathInDocumentsDirectory:databaseFileName];
}

+ (BOOL)databaseWasCreated {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self pathToDatabase]];
}

+ (BOOL)databaseCreateWithError:(NSError **)error {
    
    // Create the database
    TSDatabaseManager *db = [TSDatabaseManager  databaseCreateAtFilePath:[self pathToDatabase] updateBoolPreference:kDBWasCreatedBool error:error];
    if (!db) {
        return NO;
    }
    
    // Create the tables we need
    __block BOOL dbInitSuccess = NO;
    [db.dbQueue inDatabase:^(FMDatabase *db) {
        
        if (![db executeUpdate:@"CREATE TABLE settings (setting_name TEXT UNIQUE,setting_value TEXT)"]) {
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS contacts (registered_id TEXT PRIMARY KEY, relay TEXT, identityKey BLOB UNIQUE, device_ids BLOB, verifiedIdentity INTEGER)"]) {
            return;
        }
        
#warning incomplete implementation of groups
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS groups (group_id TEXT PRIMARY KEY)"]) {
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (FOREIGN KEY(sender_id) REFERENCES contacts(registered_id), FOREIGN KEY(recipient_id) REFERENCES contacts(registered_id), FOREIGN KEY(group_id) REFERENCES groups(group_id), message TEXT, timestamp DATE, attachements BLOB, state INTEGER)"]) {
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS personal_prekeys (prekey_id INTEGER PRIMARY KEY,public_key TEXT,private_key TEXT, last_counter INTEGER)"]){
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS threads (thread_id TEXT PRIMARY KEY, rk BLOB, cks BLOB, ckr BLOB, dhis BLOB, dhir BLOB, dhrs BLOB, dhrr BLOB, ns INT, nr INT, pns INT)"]) {
            return;
        }
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS missed_messages (skipped_MK BLOB,skipped_HKs BLOB, skipped_HKr BLOB,thread_id TEXT,FOREIGN KEY(thread_id) REFERENCES threads(thread_id))"]) {
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


+ (void)databaseErase {
    [TSDatabaseManager databaseEraseAtFilePath:[self pathToDatabase] updateBoolPreference:kDBWasCreatedBool];
}

+ (BOOL)databaseOpenWithError:(NSError **)error {
    
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
    
    messagesDb = [TSDatabaseManager databaseOpenAndDecryptAtFilePath:[self pathToDatabase] error:error];
    if (!messagesDb) {
        return NO;
    }
    return YES;
}

#pragma mark Settings table

+ (BOOL)storePersistentSettings:(NSDictionary*)settingNamesAndValues {
    openDBMacroBOOL;
    
    __block BOOL updateSuccess = YES;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        for(NSString *settingName in settingNamesAndValues) {
            if (![db executeUpdate:@"INSERT OR REPLACE INTO settings (setting_name,setting_value) VALUES (:setting_name, :setting_value)", settingNamesAndValues]) {
                DLog(@"Error updating DB: %@", [db lastErrorMessage]);
                updateSuccess = NO;
            }
        }
    }];
    
    return updateSuccess;
}

+ (NSString*)settingForKey:(NSString*)key {
    openDBMacroNil
    
    __block NSString *settingValue = nil;
    
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT setting_value FROM settings WHERE setting_name=?" withArgumentsInArray:@[key]];
        
        if ([searchInDB next]) {
            settingValue = [searchInDB stringForColumn:key];
        }
        [searchInDB close];
    }];
    
    return settingValue;
}


#pragma mark Contacts table

+ (BOOL)storeContact:(TSContact*)contact {
    openDBMacroBOOL
    
    __block BOOL updateSuccess = YES;
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        if (![db executeUpdate:@"INSERT OR REPLACE INTO contacts (registered_id, relay, identityKey, device_ids, verifiedIdentity) VALUES (?, ?, ?, ?, ?)" withArgumentsInArray:@[contact.registeredID, contact.relay, contact.identityKey, [NSKeyedArchiver archivedDataWithRootObject:contact.deviceIDs], ]]) {
            DLog(@"Error updating DB: %@", [db lastErrorMessage]);
            updateSuccess = NO;
        }
    }];
    
    return updateSuccess;
}

+ (BOOL)storeContacts:(NSArray*)contacts {
    BOOL success = YES;
    for (TSContact *contact in contacts) {
        success = ([self storeContact:contact])?:NO;
    }
    return success;
}

- (TSContact*)contactForRegisteredID:(NSString*)registredID {
    openDBMacroNil
    
    __block TSContact *contact = nil;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM contacts WHERE registeredID=?" withArgumentsInArray:@[registredID]];
        
        if ([searchInDB next]) {
            contact = [[TSContact alloc] initWithRegisteredID:[searchInDB stringForColumn:@"registeredID"] relay:[searchInDB stringForColumn:@"relay"]];
            contact.identityKey = [searchInDB dataForColumn:@"identityKey"];
            NSData *deviceIds = [searchInDB dataForColumn:@"deviceIds"];
            if (deviceIds) {
                contact.deviceIDs = [NSKeyedUnarchiver unarchiveObjectWithData:deviceIds];
            }
            contact.identityKeyIsVerified = [searchInDB boolForColumn:@"verifiedIdentity"];
        }
        [searchInDB close];
    }];
    
    return contact;
}

+ (NSArray*) contacts{
    openDBMacroNil
    
    NSMutableArray *contacts = [NSMutableArray array];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT registered_id FROM contacts"];
        
        while ([searchInDB next]) {
            [contacts addObject:[searchInDB stringForColumn:@"registered_id"]];
        }
        [searchInDB close];
    }];
    
    return [contacts copy];
}

#pragma mark Sessions table

#pragma mark Messages table

+ (BOOL)storeMessage:(TSMessage*)msg {
    openDBMacroBOOL
    
    __block TSMessage *message = msg;
    __block BOOL success = NO;
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        int state = *(message.state);
        
        success = [db executeUpdate:@"INSERT INTO messages (sender_id, recipient_id, group_id, message, timestamp, attachements, state) VALUES (?, ?, ?, ?, ?)" withArgumentsInArray:@[message.senderId, message.recipientId, message.group.id, message.content, message.timestamp, message.attachments, [NSNumber numberWithInt:state]]];
    }];
    
    return success;
}

+ (TSMessage*)messageForDBElement:(FMResultSet*)messages{
    //To determine if it's an incoming or outgoing message, we look if there is a sender_id
    NSString *senderID = [messages stringForColumn:@"sender_id"];
    NSString *receiverID = [messages stringForColumn:@"recipient_id"];
    
    NSDate *date = [messages dateForColumn:@"timestamp"];
    NSString *content = [messages stringForColumn:@"content"];
    NSArray *attachements = [NSKeyedUnarchiver unarchiveObjectWithData:[messages dataForColumn:@"attachements"]];
    //NSString *groupID = [messages stringForColumn:@"group_id"];
    int state = [messages intForColumn:@"state"];
    
    if (senderID) {
#warning Groupmessaging not yet supported
        TSMessageIncoming *incoming = [[TSMessageIncoming alloc] initWithMessageWithContent:content sender:senderID date:date attachements:attachements group:nil state:state];
        
        return incoming;
    } else{
        TSMessageOutgoing *outgoing = [[TSMessageOutgoing alloc] initWithMessageWithContent:content recipient:receiverID date:date attachements:attachements group:nil state:state];
        return outgoing;
    }
}

+ (NSArray*)messagesWithContact:(TSContact*)contact numberOfPosts:(int)numberOfPosts{
    // -1 returns everything
    openDBMacroNil
    
    __block int nPosts = numberOfPosts;
    
    __block NSMutableArray *messagesArray = [NSMutableArray array];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *messages= [db executeQuery:@"SELECT * FROM messages WHERE sender_id=? OR recipient_id=? ORDER BY timestamp DESC" withArgumentsInArray:@[contact.registeredID, contact.registeredID]];
        
        if (nPosts == -1) {
            while ([messages next]) {
                [messagesArray addObject:[self messageForDBElement:messages]];
            }
        } else {
            while ([messages next] && nPosts > 0) {
                [messagesArray addObject:[self messageForDBElement:messages]];
                nPosts --;
            }
        }
        [messages close];
    }];
    
    return [messagesArray copy];
}

+ (NSArray*)messagesWithContact:(TSContact*)contact {
    return [self messagesWithContact:contact numberOfPosts:-1];
}

+ (TSMessage*)lastMessageWithContact:(TSContact*) contact{
    openDBMacroNil
    
    __block NSMutableArray *messagesArray = [NSMutableArray array];
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *messages= [db executeQuery:@"SELECT * FROM messages WHERE sender_id=? OR recipient_id=? ORDER BY timestamp DESC" withArgumentsInArray:@[contact.registeredID, contact.registeredID]];
        
        if ([messages next]) {
            [messagesArray addObject:[self messageForDBElement:messages]];
        }
        
        [messages close];
        
    }];
    
    if ([messagesArray count] == 1) {
        return [messagesArray lastObject];
    } else{
        return nil;
    }
}

+ (NSArray*)messagesForGroup:(TSGroup*)group {
    openDBMacroNil
    __block NSMutableArray *messagesArray = [NSMutableArray array];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *messages= [db executeQuery:@"SELECT * FROM messages WHERE group_id=?" withArgumentsInArray:@[group.id]];
        
        while ([messages next]) {
            [messagesArray addObject:[self messageForDBElement:messages]];
        }
        
        [messages close];
    }];
    
    return [messagesArray copy];
}

#pragma mark Conversation Methods

+ (NSArray*)conversations{
    openDBMacroNil
    
    NSArray *contacts = [self contacts];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for(TSContact* contact in contacts){

        NSArray *message = [self messagesWithContact:contact numberOfPosts:1];
        
        if ([message count] == 1) {
            TSMessage *tsMessage = [message lastObject];
            TSConversation *conversation = [[TSConversation alloc]initWithLastMessage:tsMessage.content contact:contact lastDate:tsMessage.timestamp containsNonReadMessages:[tsMessage isUnread]];
            [array addObject:conversation];
        }
    }
    
    return array;
}

#pragma mark Groups table

#warning TODO

#pragma mark Attachements

#warning TODO

#pragma mark Sessions

+ (NSData *)APSDataField:(NSString *)name onSession:(TSSession*)session {
    openDBMacroNil
    
    __block NSData * apsField;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"threadID":session}];
        if ([searchInDB next]) {
            apsField= [searchInDB dataForColumn:name];
        } else{
            DLog(@"No results found!")
        }
        [searchInDB close];
    }];
    return apsField;
}

+(NSNumber*) APSIntField:(NSString*)name onSession:(TSSession*)session {
    openDBMacroNil
    __block NSNumber* apsField = 0;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"session":session}];
        if ([searchInDB next]) {
            apsField = [NSNumber numberWithInt:[searchInDB intForColumn:name]];
        }
        [searchInDB close];
    }];
    return apsField;
}

+(BOOL) APSBoolField:(NSString*)name onSession:(TSSession*)session {
    openDBMacroBOOL
    __block int apsField = 0;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"threadID":session}];
        if ([searchInDB next]) {
            apsField= [searchInDB boolForColumn:name];
        }
        [searchInDB close];
    }];
    return apsField;
}

+(NSString*) APSStringField:(NSString*)name onSession:(TSSession*)session {
    openDBMacroNil
    __block NSString* apsField = nil;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM threads WHERE thread_id = :threadID " withParameterDictionary:@{@"threadID":session}];
        if ([searchInDB next]) {
            apsField= [searchInDB stringForColumn:name];
        }
        [searchInDB close];
    }];
    return apsField;
}

+(void) setAPSDataField:(NSDictionary*) parameters{
    
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
    
    NSString* query = [NSString stringWithFormat:@"UPDATE threads SET %@ = ? WHERE thread_id = ?",[parameters objectForKey:@"nameField"]];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:query withArgumentsInArray:@[[parameters objectForKey:@"valueField"], [parameters objectForKey:@"threadID"]]];
    }];
}

+(NSString*) APSFieldName:(NSString*)name onChain:(TSChainType)chain{
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
+(NSData*) RK:(TSSession*)session{
    return [TSMessagesDatabase APSDataField:@"rk"  onSession:session];
}

+(void) setRK:(NSData*)key onSession:(TSSession*)session{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":@"rk",@"valueField":key,@"session":session}];
}
/* Chain keys */
+(NSData*) CK:(TSSession*)session onChain:(TSChainType)chain{
    return [TSMessagesDatabase APSDataField:[TSMessagesDatabase APSFieldName:@"ck" onChain:chain] onSession:session];
    
}
+(void) setCK:(NSData*)key onSession:(TSSession*)session onChain:(TSChainType)chain{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase APSFieldName:@"ck" onChain:chain],@"valueField":key,@"session":session}];
}

/* ephemeral keys of chains */
+(NSData*) ephemeralOfReceivingChain:(TSSession*)session{
    return [TSMessagesDatabase APSDataField:[TSMessagesDatabase APSFieldName:@"dhr" onChain:TSReceivingChain ] onSession:session];
}

+(TSECKeyPair*) ephemeralOfSendingChain:(TSSession*)session {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[TSMessagesDatabase APSDataField:[TSMessagesDatabase APSFieldName:@"dhr" onChain:TSSendingChain] onSession:session]];
}

+(void) setEphemeralOfReceivingChain:(NSData*)key onSession:(TSSession*)session {
    [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase APSFieldName:@"dhr" onChain:TSReceivingChain],@"valueField":key,@"threadID":session}];
}

+(void) setEphemeralOfSendingChain:(TSECKeyPair*)key onSession:(TSSession*)session {
    [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase APSFieldName:@"dhr" onChain:TSSendingChain],@"valueField":[NSKeyedArchiver archivedDataWithRootObject:key],@"threadID":session}];
}

/* number of messages sent on chains */
+(NSNumber*) N:(TSSession*)session onChain:(TSChainType)chain {
    NSNumber *num = [TSMessagesDatabase APSIntField:[TSMessagesDatabase APSFieldName:@"n" onChain:chain] onSession:session];
    if (!num) {
        num = [NSNumber numberWithBool:0];
    }
    return num;
}

+(void) setN:(NSNumber*)num onSession:(TSSession*)session onChain:(TSChainType)chain {
    [TSMessagesDatabase setAPSDataField:@{@"nameField":[TSMessagesDatabase APSFieldName:@"n" onChain:chain],@"valueField":num,@"threadID":session}];
}

/* number of messages sent on the last chain */
+(NSNumber*)PNs:(TSSession*)session {
    return [TSMessagesDatabase APSIntField:@"pns" onSession:session];
}
+(void)setPNs:(NSNumber*)num onSession:(TSSession*)session{
    [TSMessagesDatabase setAPSDataField:@{@"nameField":@"pns",@"valueField":num,@"threadID":session}];
}

//Ns, Nr: sets N to N+1 returns value of N prior to setting,  Message numbers (reset to 0 with each new ratchet)
+(NSNumber*) NThenPlusPlus:(TSSession*)session onChain:(TSChainType)chain{
    NSNumber *n =[TSMessagesDatabase N:session onChain:chain];
    
    if ([n intValue] < INT32_MAX) {
        [TSMessagesDatabase setN:[NSNumber numberWithInt:[n intValue]+1] onSession:session onChain:chain];
    } else {
        [TSMessagesDatabase setN:[NSNumber numberWithInt:0] onSession:session onChain:chain];
    }
    
    return n;
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
