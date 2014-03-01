//
//  TSMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessage.h"

@implementation TSMessage

- (instancetype)initWithSenderId:(NSString*)senderId recipientId:(NSString*)recipientId date:(NSDate*)date content:(NSString*)content attachements:(NSArray*)attachements groupId:(TSGroup*)group{
    self = [super init];
    
    if (self) {
        _senderId = senderId;
        _recipientId = recipientId;
        _timestamp = date;
        _content = content;
        _attachments = attachements;
        _group = group;
    }
    
    return self;
}

- (BOOL)isUnread{
    NSLog(@"TSMessage can't be instantiated!");
    exit(1);
}

@end
