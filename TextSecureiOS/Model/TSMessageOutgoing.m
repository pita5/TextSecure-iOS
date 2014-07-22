//
//  TSMessageOutgoing.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageOutgoing.h"
#import "TSMessagesDatabase.h"
#import "TSGroup.h"
@interface TSMessageOutgoing ()
@end

@implementation TSMessageOutgoing

- (instancetype)initMessageWithContent:(NSString *)text recipient:(NSString *)recipientId date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageOutgoingState)state{
    
    self = [super initWithSenderId:[TSKeyManager getUsernameToken] recipientId:recipientId date:timestamp content:text attachements:attachements groupId:group];
    
    if (self) {
        _state = state;
    }
    
    return self;
}

- (instancetype)initMessageWithContent:(NSString *)text recipient:(NSString *)recipientId date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageOutgoingState)state messageId:(NSString*)messageId{
    self = [self initMessageWithContent:text recipient:recipientId date:timestamp attachements:attachements group:group state:state];
    
    if (self) {
        _messageId = messageId;
    }
    return self;
}


- (instancetype)copyMessageToRecipient:(NSString *)newRecipientId {
    return [[TSMessageOutgoing alloc] initMessageWithContent:self.content recipient:newRecipientId date:self.timestamp attachements:self.attachments group:[self.group copy] state:self.messageState];
}

- (void)setState:(TSMessageOutgoingState)state withCompletion:(TSMessageChangeState)block{
    BOOL didSucceed;
    didSucceed = [TSMessagesDatabase storeMessage:self];
    _state = state;
    block(didSucceed);
}

- (BOOL)isUnread{
    return false;
}

@end