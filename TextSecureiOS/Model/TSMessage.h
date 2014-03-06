//
//  TSMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//


#import <Foundation/Foundation.h>
@class TSContact;
@class TSGroup;

typedef void (^TSMessageChangeState)(BOOL success);

@interface TSMessage : NSObject

@property (nonatomic, readonly) NSString *senderId;
@property (nonatomic, readonly) NSString *recipientId;
@property (nonatomic, readonly) NSDate *timestamp;
@property (nonatomic, readonly) NSString *content;
@property (nonatomic, readonly) NSArray *attachments;
@property (nonatomic, readonly) TSGroup *group;
@property (nonatomic, readonly) int *state;

-(BOOL) isUnread;

- (instancetype)initWithSenderId:(NSString*)senderId recipientId:(NSString*)recipientId date:(NSDate*)date content:(NSString*)content attachements:(NSArray*)attachements groupId:(TSGroup*)group;

@end
