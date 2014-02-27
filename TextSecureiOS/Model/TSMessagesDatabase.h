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
@class TSThread;
@class TSContact;

typedef void(^dataBaseFetchCompletionBlock)(NSArray* array);
typedef void(^dataBaseUpdateCompletionBlock)(BOOL success); // For retreival of arrays


/**
 * Posted when the database receives an update
 */
extern NSString * const TSDatabaseDidUpdateNotification;


@interface TSMessagesDatabase : NSObject<AxolotlPersistantStorage>


+(BOOL) databaseCreateWithError:(NSError **)error;
+(void) databaseErase;
+(BOOL) databaseWasCreated;

// Calling the following functions will fail if the storage master key hasn't been unlocked

#pragma mark - settings values
+(BOOL) storePersistentSettings:(NSDictionary*)settingNamesAndValues;

#pragma mark - DB message functions
+(NSArray*) threads;
+(NSArray*) messagesOnThread:(TSThread*) thread;

+(void) deleteThread:(TSThread*)thread withCompletionBlock:(dataBaseUpdateCompletionBlock) block; // deleting a thread is done by user activity -
+(void) storeMessage:(TSMessage*)message fromThread:(TSThread*)thread;

+(void)storeContact:(TSContact*)contact;
+(void)storeThread:(TSThread*)thread;

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

