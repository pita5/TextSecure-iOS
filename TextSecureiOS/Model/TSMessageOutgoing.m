//
//  TSMessageOutgoing.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageOutgoing.h"
#import "TSMessagesDatabase.h"

@interface TSMessageOutgoing ()
@end

@implementation TSMessageOutgoing

- (instancetype)initWithMessageWithContent:(NSString *)text recipient:(NSString *)recipientId date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageOutgoingState)state{
    
    self = [super init];
    if (self) {
        _content = text;
        _recipientId = recipientId;
        _senderId = [TSKeyManager getUsernameToken];
        _timestamp = timestamp;
        _group = group;
        _attachments = attachements;
        _state = state;
        return self;
    }
    return nil;
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
