//
//  Message.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSAttachment;
@interface TSMessage : NSObject
@property (nonatomic,strong) NSString *senderId;
@property (nonatomic,strong) NSString *recipientId;
@property (nonatomic,strong) NSDate *messageTimestamp;
@property (nonatomic,strong) NSString* message;
@property (nonatomic,strong) TSAttachment* attachment;

-(id) initWithMessage:(NSString*)text sender:(NSString*)sender recipients:(NSArray*)recipients sentOnDate:(NSDate*)date attachment:(TSAttachment*) attachment;

@end
