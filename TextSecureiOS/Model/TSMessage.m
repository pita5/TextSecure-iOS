//
//  TSMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessage.h"
#import "NSString+randomString.h"
#import "TSGroup.h"
@implementation TSMessage

- (instancetype)initWithSenderId:(NSString*)senderId recipientId:(NSString*)recipientId date:(NSDate*)date content:(NSString*)content attachements:(NSArray*)attachements groupId:(TSGroup*)group{
    self = [super init];
    
    if (self) {
        _messageId = [NSString genRandStringLength:20];
        _senderId = senderId;
        _recipientId = recipientId;
        _timestamp = date;
        _content = content;
        _attachments = attachements;
        _group = group;
        if(group!=nil) {
            _metaMessage = group.groupContext.type;
        }
    }
    
    return self;
}

- (instancetype)initWithSenderId:(NSString*)senderId recipientId:(NSString*)recipientId date:(NSDate*)date content:(NSString*)content attachements:(NSArray*)attachements groupId:(TSGroup*)group messageId:(NSString*)messageid{
    self = [self initWithSenderId:senderId recipientId:recipientId date:date content:content attachements:attachements groupId:group];
    
    if (self) {
        _messageId = messageid;
    }
    
    return self;
}

- (BOOL)isUnread{
    NSLog(@"TSMessage can't be instantiated!");
    exit(1);
}

@end
