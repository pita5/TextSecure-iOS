//
//  TSMessageIncoming.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageIncoming.h"

@interface TSMessageIncoming ()
@property (nonatomic, copy) NSString *senderId;
@property (nonatomic, copy) NSString *recipientId;
@property (nonatomic, copy) NSDate *timestamp;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, retain) NSArray *attachments;
@property (nonatomic, copy) TSGroup *group;
@property TSMessageIncomingState state;
@end

@implementation TSMessageIncoming

-(instancetype) initWithMessageWithContent:(NSString *)text sender:(NSString *)sender date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageIncomingState)state{
    
    self = [super init];
    if (self) {
        self.content = text;
        self.senderId = sender;
        self.recipientId = [TSKeyManager getUsernameToken];
        self.timestamp = timestamp;
        self.group = group;
        self.attachments = attachements;
        return self;
    }
    return  nil;
}

- (void)setState:(TSMessageIncomingState)state withCompletion:(TSMessageChangeState)block{
    
    // TO DO : SAVE SELF THEN COMPLETION BLOCK
    self.state = state;
    
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
