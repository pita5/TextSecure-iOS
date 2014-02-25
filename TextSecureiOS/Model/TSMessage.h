//
//  TSMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//


#import <Foundation/Foundation.h>
@class TSContact;
@class TSAttachment;


@interface TSMessage : NSObject

@property (nonatomic,strong,readonly) NSString *senderId;
@property (nonatomic,strong,readonly) NSString *recipientId;
@property (nonatomic,strong,readonly) NSDate *timestamp;
@property (nonatomic,strong,readonly) NSString *content;
@property (nonatomic,strong,readonly) TSAttachment *attachment;

+(instancetype) messageWithContent:(NSString *)text sender:(NSString *)senderId recipient:(NSString *)recipientId date:(NSDate *)date;
+(instancetype) messageWithContent:(NSString *)text sender:(NSString *)senderId recipient:(NSString *)recipientId date:(NSDate *)date attachment:(TSAttachment *)attachment;

@end
