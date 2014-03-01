//
//  TSMessagesDatabase.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocols.h"

@class TSMessage;
@class TSContact;

typedef void(^dataBaseFetchCompletionBlock)(NSArray* array);
typedef void(^dataBaseUpdateCompletionBlock)(BOOL success); // For retreival of arrays

/**
 *  The TSMessagesDatabase contains everything used for messaging
 *  It contains 6 tables - contacts, sessions, messages, groups, attachements, settings
 */

@interface TSMessagesDatabase : NSObject<AxolotlPersistantStorage>

+(BOOL) databaseCreateWithError:(NSError **)error;
+(void) databaseErase;
+(BOOL) databaseWasCreated;

// Calling the following functions will fail if the storage master key hasn't been unlocked

#pragma mark - settings values
+(BOOL) storePersistentSettings:(NSDictionary*)settingNamesAndValues;

+(BOOL) storeContact:(TSContact*)contact;

#pragma mark Messages

+ (NSArray*)messagesWithContact:(TSContact*)contact;

#pragma mark - AxolotlEphemeralStorage protocol getter/setter helper methods

#pragma mark - AxolotlPersistantStorage protocol getter/setter helper methods

+(NSData*) APSDataField:(NSString*)name onThread:(TSThread*)thread;
+(NSNumber*) APSIntField:(NSString*)name onThread:(TSThread*)thread;
+(BOOL) APSBoolField:(NSString*)name onThread:(TSThread*)thread;
+(NSString*) APSStringField:(NSString*)name  onThread:(TSThread*)thread;
+(NSString*) APSFieldName:(NSString*)name onChain:(TSChainType) chain;

/*
 parameters
 nameField : name of db field to set
 valueField : value of db field to set to
 threadID" : thread id
 */

+(void) setAPSDataField:(NSDictionary*) parameters;

@end

