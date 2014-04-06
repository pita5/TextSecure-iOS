//
//  TSPushMessageContent.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocolBufferWrapper.hh"
#import "TSGroupContext.h"

@class TSMessage;

@interface TSPushMessageContent :  TSProtocolBufferWrapper
@property (readonly,nonatomic,strong) NSString* body;
@property (readonly,nonatomic,strong) NSArray* attachments;
@property (readonly,nonatomic,strong) TSGroupContext* groupContext;
@property (readonly,nonatomic,assign) TSPushMessageFlags messageFlags;
@property (readonly,nonatomic,strong) NSData *serializedProtocolData;

-(instancetype) initWithBody:(NSString*)body withAttachments:(NSArray*)attachments withGroupContext:(TSGroupContext*)groupContext;

+ (NSData *)serializedPushMessageContentForMessage:(TSMessage*) message  withGroupContect:(TSGroupContext*)groupContext;
@end
