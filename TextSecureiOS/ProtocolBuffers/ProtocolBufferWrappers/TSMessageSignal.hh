//
//  TSMessageSignal.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocolBufferWrapper.hh"
#import "TSProtocols.h"
@class TSPushMessageContent;
@class TSWhisperMessage;
@interface TSMessageSignal : TSProtocolBufferWrapper
@property (nonatomic) TSWhisperMessageType contentType;
@property (nonatomic,strong) NSString* source;
@property (nonatomic,strong) NSArray *destinations;
@property (nonatomic,strong) NSDate *timestamp;
@property (nonatomic,strong) TSWhisperMessage *message;
-(TSMessage*) getTSMessage:(TSPushMessageContent*) pushMessageContent;
@end
