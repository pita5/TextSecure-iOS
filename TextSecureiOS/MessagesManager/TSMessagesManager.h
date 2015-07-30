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
#import "TSContact.h"
#import "TSGroup.h"
@class TSMessageOutgoing;

@interface TSMessagesManager : NSObject

+ (id)sharedManager;

- (void) receiveMessagePush:(NSDictionary*)pushDict;

// Methods for sending messages should be - schedule send, cancel send
-(void) scheduleMessageSend:(TSMessageOutgoing*)message; // Sending messages should have a completion block for UI processing

-(void) submitMessage:(TSMessageOutgoing*)message to:(NSString*)recipientId serializedMessage:(NSString*)serializedMessage ofType:(TSWhisperMessageType)messageType;

@end
