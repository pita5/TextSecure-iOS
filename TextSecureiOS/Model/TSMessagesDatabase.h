//
//  TSMessagesDatabase.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TSSession;
@class TSMessage;
@class TSContact;

typedef void(^dataBaseFetchCompletionBlock)(NSArray* array);
typedef void(^dataBaseUpdateCompletionBlock)(BOOL success); // For retreival of arrays

/**
 *  The TSMessagesDatabase contains everything used for messaging
 *  It contains 6 tables - contacts, sessions, messages, groups, attachements, settings
 */

@interface TSMessagesDatabase : NSObject

+ (BOOL)databaseCreateWithError:(NSError **)error;
+ (void)databaseErase;
+ (BOOL)databaseWasCreated;

// Calling the following functions will fail if the storage master key hasn't been unlocked

#pragma mark Settings
+ (BOOL)storePersistentSettings:(NSDictionary*)settingNamesAndValues;

#pragma mark Contacts

+ (TSContact*)contactForRegisteredID:(NSString*)registredID;
+ (BOOL)storeContact:(TSContact*)contact;

#pragma mark Sessions

/**
 *  A session contains all information required by the Axolotl ratchet. It is unique to a registeredID and a deviceID. Because in the future, TS users will be able to add many devices to a single identity key/registered ID, we have to make sure that we can support multiple sessions with a TSContact.
 */
+ (BOOL)sessionExistsForContact:(TSContact*)contact;
+ (BOOL)deleteSession:(TSSession*)session;
+ (BOOL)storeSession:(TSSession*)session;
+ (NSArray*)sessionsForRegisteredId:(NSString*)registeredId;
+ (TSSession*)sessionForRegisteredId:(NSString*)registeredId deviceId:(int)deviceId;

#pragma mark Messages

+ (NSArray*)messagesWithContact:(TSContact*)contact;
+ (BOOL)storeMessage:(TSMessage*)msg;

@end

