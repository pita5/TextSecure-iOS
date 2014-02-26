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
typedef void(^dataBaseFetchDataCompletionBlock)(NSData* data);
typedef void(^dataBaseFetchIntCompletionBlock) (NSNumber*);
typedef void(^dataBaseFetchBOOLCompletionBlock) (BOOL success);
typedef void(^dataBaseFetchStringCompletionBlock) (NSString*);
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
+(void) storeMessage:(TSMessage*)message fromThread:(TSThread*)thread withCompletionBlock:(dataBaseUpdateCompletionBlock) block;
+(void) getMessagesOnThread:(TSThread*) thread withCompletion:(dataBaseFetchCompletionBlock) block;
+(void) deleteTSThread:(TSThread*)thread withCompletionBlock:(dataBaseUpdateCompletionBlock) block;
+(void) getThreadsWithCompletion:(dataBaseFetchCompletionBlock) block;
+(void)storeTSContact:(TSContact*)contact withCompletionBlock:(dataBaseUpdateCompletionBlock) block;
+(void)storeTSThread:(TSThread*)thread withCompletionBlock:(dataBaseUpdateCompletionBlock) block;

#pragma mark - AxolotlEphemeralStorage protocol getter/setter helper methods

#pragma mark - AxolotlPersistantStorage protocol getter/setter helper methods

+(void) getAPSDataField:(NSString*)name onThread:(TSThread*)thread withCompletion:(dataBaseFetchDataCompletionBlock) block;
+(void) getAPSIntField:(NSString*)name onThread:(TSThread*)thread withCompletion:(dataBaseFetchIntCompletionBlock) block;
+(void) getAPSBoolField:(NSString*)name onThread:(TSThread*)thread withCompletion:(dataBaseFetchBOOLCompletionBlock) block;
+(void) getAPSStringField:(NSString*)name  onThread:(TSThread*)thread withCompletion:(dataBaseFetchStringCompletionBlock) block;
+(NSString*) getAPSFieldName:(NSString*)name onChain:(TSChainType) chain ;
/*
 parameters
 nameField : name of db field to set
 valueField : value of db field to set to
 threadID" : thread id
 */
+(void) setAPSDataField:(NSDictionary*) parameters withCompletion:(dataBaseUpdateCompletionBlock) block;;

@end

