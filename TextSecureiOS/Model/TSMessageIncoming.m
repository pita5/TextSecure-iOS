//
//  TSMessageIncoming.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageIncoming.h"

@interface TSMessageIncoming ()
@end

@implementation TSMessageIncoming

-(instancetype) initWithMessageWithContent:(NSString *)text sender:(NSString *)sender date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageIncomingState)state{
    
    self = [super init];
    if (self) {
        _content = text;
        _senderId = sender;
        _recipientId = [TSKeyManager getUsernameToken];
        _timestamp = timestamp;
        _group = group;
        _attachments = attachements;
        return self;
    }
    return  nil;
}

- (void)setState:(TSMessageIncomingState)state withCompletion:(TSMessageChangeState)block{
    
    // TO DO : SAVE SELF THEN COMPLETION BLOCK
    _state = state;
    
    block(YES);
}

-(BOOL) isUnread{
    if (self.state == TSMessageStateReceived) {
        return YES;
    } else{
        return NO;
    }
}


@end
