//
//  MessagesManager.h
//  TextSecureiOS`
//
//  Created by Frederic Jacobs on 30/11/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

/**
 *  The Messages Manager class is crucial, it does do all the Messages processing (push notifications, sending)
 *  The TSMessager is blocking and does work on
 *
 */


#import <Foundation/Foundation.h>
#import "TSProtocols.h"
#import "TSContact.h"
#import "TSGroup.h"
@class TSMessage;

@interface TSMessagesManager : NSObject

+ (id)sharedManager;

- (void) receiveMessagePush:(NSDictionary*)pushDict;

// Methods for sending messages should be - shedule send, cancel send
-(void) sendMessage:(TSMessage*)message toContact:(TSContact*)contact; // Sending messages should have a completion block for UI processing
-(void) sendMessage:(TSMessage *)message toGroup:(TSGroup*)group;

-(void) submitMessageTo:(NSString*)recipientId message:(NSString*)serializedMessage ofType:(TSWhisperMessageType)messageType;

@end
