//
//  TSMessageIncoming.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageIncoming.h"
#import "TSMessagesDatabase.h"

@interface TSMessageIncoming ()
@end

@implementation TSMessageIncoming

-(instancetype) initMessageWithContent:(NSString *)text sender:(NSString *)sender date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageIncomingState)state{
    self = [super initWithSenderId:sender recipientId:[TSKeyManager getUsernameToken] date:timestamp content:text attachements:attachements groupId:group];
    
    if (self) {
        _state = state;
    }
    return self;
}

-(instancetype) initMessageWithContent:(NSString *)text sender:(NSString *)sender date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageIncomingState)state messageId:(NSString*)messageId{
    self = [self initMessageWithContent:text sender:sender date:timestamp attachements:attachements group:group state:state];
    if (self) {
        _messageId = messageId;
    }
    return self;
}

- (void)setState:(TSMessageIncomingState)state withCompletion:(TSMessageChangeState)block{
    BOOL didSucceed;
    didSucceed = [TSMessagesDatabase storeMessage:self];
    _state = state;
    block(didSucceed);
}

-(BOOL) isUnread{
    if (self.state == TSMessageStateReceived) {
        return YES;
    } else{
        return NO;
    }
}


@end
