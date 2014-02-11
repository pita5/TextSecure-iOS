//
//  TSMessage.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessage.h"

@implementation TSMessage


+(instancetype) messageWithContent:(NSString *)text sender:(NSString *)senderId recipient:(NSString *)recipientId date:(NSDate *)date {
    return [TSMessage messageWithContent:text sender:senderId recipient:(NSString *)recipientId date:date attachment:nil];
}


+(instancetype) messageWithContent:(NSString *)text sender:(NSString *)senderId recipient:(NSString *)recipientId date:(NSDate *)date attachment:(TSAttachment *)attachment{
    
    TSMessage *message = [[TSMessage alloc] init];
    if (message == nil) {
        return nil;
    }
    message->_content = text;
    message->_senderId = senderId;
    message->_recipientId = recipientId;
    message->_timestamp = date;
    message->_attachment = attachment;
    
    return message;
}


@end
