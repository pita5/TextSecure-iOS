//
//  MessagesManager.h
//  TextSecureiOS`
//
//  Created by Frederic Jacobs on 30/11/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

// The Messages Manager class is crucial, it does do all the Messages processing.
// It gets push notifications payloads and processes them and does hence work heavily with the database.


#import <Foundation/Foundation.h>
#import "TSProtocols.h"
@class TSMessage;

@interface TSMessagesManager : NSObject
+ (id)sharedManager;

- (void) receiveMessagePush:(NSDictionary*)pushDict;
-(void) sendMessage:(TSMessage*)message onThread:(TSThread*)thread;
-(void) submitMessageTo:(NSString*)recipientId message:(NSString*)serializedMessage ofType:(TSWhisperMessageType)messageType;

@end
