//
//  TSMessageOutgoing.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageOutgoing.h"

@interface TSMessageOutgoing ()
@property (nonatomic, copy) NSString *senderId;
@property (nonatomic, copy) NSString *recipientId;
@property (nonatomic, copy) NSDate *timestamp;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, retain) NSArray *attachments;
@property (nonatomic, copy) TSGroup *group;
@property TSMessageOutgoingState state;
@end

@implementation TSMessageOutgoing

- (instancetype)initWithMessageWithContent:(NSString *)text recipient:(NSString *)recipientId date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageOutgoingState)state{
    
    self = [super init];
    if (self) {
        self.content = text;
        self.recipientId = recipientId;
        self.senderId = [TSKeyManager getUsernameToken];
        self.timestamp = timestamp;
        self.group = group;
        self.attachments = attachements;
        self.state = state;
        return self;
    }
    return nil;
}

- (void)setState:(TSMessageOutgoingState)state withCompletion:(TSMessageChangeState)block{
    
    // TO DO : SAVE SELF THEN COMPLETION BLOCK
    self.state = state;
    block(YES);
}

- (BOOL)isUnread{
    return false;
}

@end
