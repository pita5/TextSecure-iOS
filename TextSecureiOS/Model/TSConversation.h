//
//  TSConversation.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSMessage.h"
#import "TSGroup.h"

/**
 *  TSConversation is a datastructure used to display a conversation in the message inbox.
 */

@interface TSConversation : NSObject

#pragma mark TSConversation messages info

@property (readonly) BOOL containsNotReadMessages;
@property (nonatomic, readonly) NSString *lastMessage;
@property (nonatomic, readonly) NSDate *lastMessageDate;

#pragma mark TSConversation contact info

- (BOOL)isGroupConversation;

@property(nonatomic, readonly) TSContact *contact;
@property(nonatomic, readonly) TSGroup *group;

#pragma mark TSConversation Constructors

- (instancetype) initWithLastMessage:(NSString*)lastMessage contact:(TSContact*)contact lastDate:(NSDate*)date containsNonReadMessages:(BOOL)nonread;

- (instancetype) initWithLastMessage:(NSString*)lastMessage group:(TSGroup*)group lastDate:(NSDate*)date containsNonReadMessages:(BOOL)nonread;

@end
