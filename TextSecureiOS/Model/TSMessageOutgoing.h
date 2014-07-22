//
//  TSMessageOutgoing.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessage.h"

typedef enum {
    TSMessageStateDraft,
    TSMessageStatePendingSend,
    TSMessageStateSent
} TSMessageOutgoingState;

@interface TSMessageOutgoing : TSMessage

@property (readonly) TSMessageOutgoingState messageState;

/**
 *  This method is used to initialize a new message when it's created, thus when it's sent.
 *
 *  @param text         Body of the message.
 *  @param recipientId  Registered id of the recipient - nil if sent to group.
 *  @param timestamp    Date at which it is created, updated when sent.
 *  @param attachements Attachements array containing TSAttachements.
 *  @param group        Group to whom the message is sent - nil if sent to individual.
 *  @param state        TSMessageOutgoingState of the current state.
 *
 *  @return An initialized TSMessageOutgoing
 */

- (instancetype)initMessageWithContent:(NSString *)text recipient:(NSString *)recipientId date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageOutgoingState)state;

/**
 *  This method is similar to initMessageWithContent:recipient:date:attachements:group:state: but contains the messageId, this method is used to retreive a message from the database with an existing messageId.
 *
 *  @param text         Body of the message.
 *  @param recipientId  Registered id of the recipient - nil if sent to group.
 *  @param timestamp    Date at which it is created, updated when sent.
 *  @param attachements Attachements array containing TSAttachements.
 *  @param group        Group to whom the message is sent - nil if sent to individual.
 *  @param state        TSMessageOutgoingState of the current state.
 *  @param messageId    Message Id of the current message
 *
 *  @return An initialized TSMessageOutgoing
 */

- (instancetype)initMessageWithContent:(NSString *)text recipient:(NSString *)recipientId date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageOutgoingState)state messageId:(NSString*)messageId;


- (instancetype)copyMessageToRecipient:(NSString *)newRecipientId;


/**
 *  This method mutates the state.
 *
 *  @param state New state
 *  @param block Completion block to pass - likely a UI update.
 */

- (void)setState:(TSMessageOutgoingState)state withCompletion:(TSMessageChangeState)block;

@end
