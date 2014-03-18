//
//  TSConversation.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSConversation.h"

@implementation TSConversation

- (instancetype)initWithMessage:(NSString*)message unread:(BOOL)unread onDate:(NSDate*)date {
    self = [super init];
    
    if (self) {
        _lastMessage = message;
        _containsNotReadMessages = unread;
        _lastMessageDate = date;
    }
    return self;
}

- (instancetype) initWithLastMessage:(NSString*)lastMessage contact:(TSContact*)contact lastDate:(NSDate*)date containsNonReadMessages:(BOOL)nonread{
    self = [self initWithMessage:lastMessage unread:nonread onDate:date];
    if (self) {
        _contact = contact;
    }
    
    return self;
}

- (instancetype) initWithLastMessage:(NSString*)lastMessage group:(TSGroup*)group lastDate:(NSDate*)date containsNonReadMessages:(BOOL)nonread{
    self = [self initWithMessage:lastMessage unread:nonread onDate:date];
    if (self) {
        _group = group;
    }
    
    return self;
}

- (BOOL) isGroupConversation {
    if (self.group) {
        return YES;
    }
    return NO;
}

@end
