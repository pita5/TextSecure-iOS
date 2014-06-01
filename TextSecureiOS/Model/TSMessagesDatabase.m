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
#import "TSChainKey.h"

#define kDBWasCreatedBool @"TSMessagesWasCreated"
#define databaseFileName @"TSMessages.db"

#define openDBMacroNothing if (!messagesDb){[TSMessagesDatabase databaseOpenWithError:nil];}
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
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS contacts (registered_id TEXT PRIMARY KEY, relay TEXT, identity_key BLOB UNIQUE, device_ids BLOB, verified_identity INTEGER)"]) {
            return;
        }
        
#warning incomplete implementation of groups
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS groups (group_id TEXT PRIMARY KEY)"]) {
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (message_id TEXT PRIMARY KEY,message TEXT, timestamp DATE, attachements BLOB, state INTEGER, sender_id TEXT, recipient_id TEXT, group_id TEXT, FOREIGN KEY(sender_id) REFERENCES contacts (registered_id), FOREIGN KEY(recipient_id) REFERENCES contacts(registered_id), FOREIGN KEY(group_id) REFERENCES groups (group_id))"]) {
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS personal_prekeys (prekey_id INTEGER PRIMARY KEY,public_key TEXT,private_key TEXT, last_counter INTEGER)"]){
            return;
        }
        
        if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS sessions (registered_id TEXT, device_id TEXT, serialized_session BLOB, FOREIGN KEY(registered_id) REFERENCES contacts (registered_id), PRIMARY KEY(registered_id, device_id))" ]) {
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

+(BOOL) storePersistentSettings:(NSDictionary*)settingNamesAndValues {
    openDBMacroBOOL;
    // Decrypt the DB if it hasn't been done yet
    if (!messagesDb) {
        if (![TSMessagesDatabase databaseOpenWithError:nil]) {
            // TODO: better error handling
            return NO;
        }
    }
    
    __block BOOL updateSuccess = YES;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        if (![db executeUpdate:@"INSERT OR REPLACE INTO settings (setting_name,setting_value) VALUES (:setting_name, :setting_value)", settingNamesAndValues]) {
            DLog(@"Error updating DB: %@", [db lastErrorMessage]);
            updateSuccess = NO;
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
        NSMutableDictionary *parameterDict = [@{@"registered_id": contact.registeredID, @"verified_identity": [NSNumber numberWithBool:contact.identityKeyIsVerified]} mutableCopy];
        
        [parameterDict setObject:contact.relay?:[NSNull null] forKey:@"relay"];
        [parameterDict setObject:contact.identityKey?:[NSNull null] forKey:@"identity_key"];
        [parameterDict setObject:contact.deviceIDs?:[NSNull null] forKey:@"device_ids"];
        
        if (![db executeUpdate:@"INSERT OR REPLACE INTO contacts VALUES (:registered_id, :relay, :identity_key, :device_ids, :verified_identity)" withParameterDictionary:parameterDict]){
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

+ (TSContact*)contactForRegisteredID:(NSString*)registredID {
    openDBMacroNil
    
    __block TSContact *contact = nil;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM contacts WHERE registered_id=?" withArgumentsInArray:@[registredID]];
        
        if ([searchInDB next]) {
            contact = [[TSContact alloc] initWithRegisteredID:[searchInDB stringForColumn:@"registered_id"] relay:[searchInDB stringForColumn:@"relay"]];
            contact.identityKey = [searchInDB dataForColumn:@"identity_key"];
            NSData *deviceIds = [searchInDB dataForColumn:@"device_ids"];
            if (deviceIds) {
                contact.deviceIDs = [NSKeyedUnarchiver unarchiveObjectWithData:deviceIds];
            }
            contact.identityKeyIsVerified = [searchInDB boolForColumn:@"verified_identity"];
        }
        [searchInDB close];
    }];
    
    if (!contact) {
        contact = [[TSContact alloc] initWithRegisteredID:registredID relay:nil];
    }
    
    return contact;
}

+ (NSArray*)contacts{
    openDBMacroNil
    
    NSMutableArray *contacts = [NSMutableArray array];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *searchInDB = [db executeQuery:@"SELECT * FROM contacts"];
        
        while ([searchInDB next]) {
            
            TSContact *contact = [[TSContact alloc] initWithRegisteredID:[searchInDB stringForColumn:@"registered_id"] relay:[searchInDB stringForColumn:@"relay"]];
            contact.identityKey = [searchInDB dataForColumn:@"identity_key"];
            NSData *deviceIds = [searchInDB dataForColumn:@"device_ids"];
            if (deviceIds) {
                contact.deviceIDs = [NSKeyedUnarchiver unarchiveObjectWithData:deviceIds];
            }
            contact.identityKeyIsVerified = [searchInDB boolForColumn:@"verified_identity"];
            [contacts addObject:contact];
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
        id groupId = message.group ? [message.group.groupContext getEncodedId]: [NSNull null];
        
        success = [db executeUpdate:@"INSERT OR REPLACE INTO messages (sender_id, recipient_id, group_id, message, timestamp, attachements, state, message_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)" withArgumentsInArray:@[message.senderId, message.recipientId, groupId, message.content, message.timestamp, [NSKeyedArchiver archivedDataWithRootObject:message.attachments], [NSNumber numberWithInt:message.state], message.messageId]];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kDBNewMessageNotification object:nil]];
    
    return success;
}

+ (TSMessage*)messageForDBElement:(FMResultSet*)messages{
    //To determine if it's an incoming or outgoing message, we look if there is a sender_id
    NSString *senderID = [messages stringForColumn:@"sender_id"];
    NSString *receiverID = [messages stringForColumn:@"recipient_id"];
    
    NSDate *date = [messages dateForColumn:@"timestamp"];
    NSString *content = [messages stringForColumn:@"message"];
    NSArray *attachements = [NSKeyedUnarchiver unarchiveObjectWithData:[messages dataForColumn:@"attachements"]];
    //NSString *groupID = [messages stringForColumn:@"group_id"];
    int state = [messages intForColumn:@"state"];
    NSString *messageId = [messages stringForColumn:@"message_id"];
    
    if (senderID) {
#warning Groupmessaging not yet supported
        TSMessageIncoming *incoming = [[TSMessageIncoming alloc] initMessageWithContent:content sender:senderID date:date attachements:attachements group:nil state:state messageId:messageId];
        
        return incoming;
    } else{
        TSMessageOutgoing *outgoing = [[TSMessageOutgoing alloc] initMessageWithContent:content recipient:receiverID date:date attachements:attachements group:nil state:state messageId:messageId];
        return outgoing;
    }
}

+ (NSArray*)messagesWithContact:(TSContact*)contact numberOfPosts:(int)numberOfPosts{
    // -1 returns everything
    openDBMacroNil
    
    __block int nPosts = numberOfPosts;
    
    __block NSMutableArray *messagesArray = [NSMutableArray array];
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *messages= [db executeQuery:@"SELECT * FROM messages WHERE sender_id=? OR recipient_id=? ORDER BY timestamp ASC" withArgumentsInArray:@[contact.registeredID, contact.registeredID]];
        
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
        FMResultSet *messages= [db executeQuery:@"SELECT * FROM messages WHERE group_id=?" withArgumentsInArray:@[[group.groupContext getEncodedId]]];
        
        while ([messages next]) {
            [messagesArray addObject:[self messageForDBElement:messages]];
        }
        
        [messages close];
    }];
    
    return [messagesArray copy];
}

+ (BOOL)deleteMessage:(TSMessage*)msg{
    openDBMacroBOOL
    
    __block BOOL success = NO;
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"DELETE FROM messages WHERE message_id=?" withArgumentsInArray:@[msg.messageId]];
    }];
    
    return success;
}

+ (void)deleteMessagesForConversation:(TSConversation*)conversation completion:(dataBaseUpdateCompletionBlock) block{
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        openDBMacroNothing
        
        NSArray *messages;
        
        if ([conversation isGroupConversation]) {
            messages = [self messagesForGroup:conversation.group];
        } else{
            messages = [self messagesWithContact:conversation.contact];
        }
        
        BOOL success = YES;
        
        for (TSMessage *message in messages){
            if (![self deleteMessage:message]) {
                success = NO;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (block) {
                block(success);
            }
        });
    });
}

+ (void)deleteMessagesAndSessionsForConversation:(TSConversation*)conversation completion:(dataBaseUpdateCompletionBlock) block{
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        openDBMacroNothing
        
        [self deleteMessagesForConversation:conversation completion:nil];
        BOOL success = FALSE;
        if (conversation.contact) {
            success = [self deleteSessions:conversation.contact];
        } else{
            //TO-DO: Implement group delete
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            block(success);
        });
    });
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

+ (BOOL)sessionExistsForContact:(TSContact*)contact{
    openDBMacroBOOL
    __block BOOL sessionExists = NO;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *session = [db executeQuery:@"SELECT * FROM sessions WHERE registered_id=?" withArgumentsInArray:@[contact.registeredID]];
        
        if ([session next]) {
            sessionExists = YES;
        }
        
        [session close];
        
    }];
    
    return sessionExists;
}

+ (BOOL)storeSession:(TSSession*)session{
    openDBMacroBOOL
    
    __block BOOL success = NO;
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"INSERT OR REPLACE INTO sessions VALUES (?, ?, ?)" withArgumentsInArray:@[session.contact.registeredID, [NSNumber numberWithInt:session.deviceId], [NSKeyedArchiver archivedDataWithRootObject:session]]];
    }];
    
    return success;
}

+ (NSArray*)sessionsForContact:(TSContact*)contact{
    openDBMacroNil
    __block NSMutableArray *sessions = [NSMutableArray array];
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *sessionResultSet = [db executeQuery:@"SELECT * FROM sessions WHERE registered_id=?" withArgumentsInArray:@[contact.registeredID]];
        while ([sessionResultSet next]) {
            TSSession *session = [NSKeyedUnarchiver unarchiveObjectWithData:[sessionResultSet dataForColumn:@"serialized_session"]];
            [session addContact:contact deviceId:[sessionResultSet intForColumn:@"device_id"]];
            [sessions addObject:session];
        }
        [sessionResultSet close];
        
    }];
    
    return [sessions copy];
}

+ (TSSession*)sessionForRegisteredId:(NSString*)registeredId deviceId:(int)deviceId{
    openDBMacroNil
    __block TSSession *session;
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *sessionResultSet = [db executeQuery:@"SELECT * FROM sessions WHERE registered_id=? AND device_id=?" withArgumentsInArray:@[registeredId, [NSNumber numberWithInt:deviceId]]];
        while ([sessionResultSet next]) {
            session = [NSKeyedUnarchiver unarchiveObjectWithData:[sessionResultSet dataForColumn:@"serialized_session"]];
        }
        [sessionResultSet close];
    }];
    
    TSContact *contact = [TSMessagesDatabase contactForRegisteredID:registeredId];
    
    if (!session) {
        session = [[TSSession alloc] initWithContact:contact deviceId:deviceId];
    } else{
        [session addContact:contact deviceId:deviceId];
    }
    
    return session;
}




+ (BOOL)deleteSession:(TSSession*)session{
    openDBMacroBOOL
    
    __block BOOL success = NO;
    
    [messagesDb.dbQueue inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:@"DELETE FROM sessions WHERE registered_id=? AND device_id=?" withArgumentsInArray:@[session.contact.registeredID, [NSNumber numberWithInt:session.deviceId]]];
    }];
    
    return success;
}

+ (BOOL)deleteSessions:(TSContact*)contact{
    openDBMacroBOOL
    NSArray *sessions = [self sessionsForContact:contact];
    
    BOOL success = TRUE;
    for (TSSession *session in sessions){
        if (![self deleteSession:session]) {
            success = FALSE;
        }
    }
    return success;
}

@end
