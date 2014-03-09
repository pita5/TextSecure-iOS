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
@property (nonatomic,strong) NSString* body;
@property (nonatomic,strong) NSArray* attachments;
@property (nonatomic,strong) TSGroupContext* groupContext;
@property (nonatomic,assign) NSNumber* groupFlags;


+ (NSData *) serializedPushMessageContent:(TSMessage*) message;
@end
