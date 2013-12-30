//
//  TSMessagesDatabase.h
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TSMessage;
@class TSContact;


@interface TSMessagesDatabase : NSObject


+(BOOL) databaseCreateWithError:(NSError **)error;
+(void) databaseErase;
+(BOOL) databaseWasCreated;


#pragma mark - settings values
+(BOOL) storePersistentSettings:(NSDictionary*)settingNamesAndValues;
+(BOOL) setDatabaseCreatedPersistantSetting ;


#pragma mark - DB message functions
+(void) storeMessage:(TSMessage*)message;
+(NSArray*) getMessagesOnThread:(NSInteger) threadId;
+(NSArray*) getThreads;
+(void)storeTSContact:(TSContact*)contact;


@end

