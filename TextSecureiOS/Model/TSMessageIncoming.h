//
//  TSMessageIncoming.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessage.h"

@interface TSMessageIncoming : TSMessage

typedef enum {
    TSMessageStateReceived,
    TSMessageStateRead
} TSMessageIncomingState;

/**
 *  This method is used to initialize a new message when it's created, thus when it's received.
 *
 *  @param text         Body of the message.
 *  @param senderid     Registered id of the sender - nil if sent to group.
 *  @param timestamp    Timestamp from when the message was sent.
 *  @param attachements Attachements array containing TSAttachements.
 *  @param group        Group to whom the message is sent - nil if sent to individual.
 *  @param state        TSMessageIncomingState of the current state.
 *
 *  @return An initialized TSMessageIncoming
 */

- (instancetype)initMessageWithContent:(NSString *)text sender:(NSString *)sender date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageIncomingState)state;

/**
 *  Method to recover a TSMessageIncoming from the database
 *
 *  @param text         Body of the message.
 *  @param senderid     Registered id of the sender - nil if sent to group.
 *  @param timestamp    Timestamp from when the message was sent.
 *  @param attachements Attachements array containing TSAttachements.
 *  @param group        Group to whom the message is sent - nil if sent to individual.
 *  @param state        TSMessageIncomingState of the current state.
 *  @param messageId    Message Id of the current message
 *
 *  @return An initialized TSMessageIncoming
 */

- (instancetype)initMessageWithContent:(NSString *)text sender:(NSString *)sender date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageIncomingState)state messageId:(NSString*)messageId;

/**
 *  This method mutates the state.
 *
 *  @param state New state
 *  @param block Completion block to pass - likely a UI update.
 */

- (void)setState:(TSMessageIncomingState)state withCompletion:(TSMessageChangeState)block;

@end