//
//  TSMessageSignal.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocolBufferWrapper.hh"
#import "TSMessage.h"
#import "Constants.h"

@class TSWhisperMessage;
@interface TSMessageSignal : TSProtocolBufferWrapper

@property (readonly,nonatomic,strong) TSWhisperMessage *message;
@property (readonly,nonatomic,strong) NSString* source;
@property (readonly,nonatomic,strong) NSNumber* sourceDevice;
@property (readonly,nonatomic) TSWhisperMessageType contentType;
@property (readonly,nonatomic,strong) NSDate *timestamp;
@property (readonly,nonatomic,strong) NSData *protocolData;


-(instancetype) initWithMessage:(TSWhisperMessage*) message withContentType:(TSWhisperMessageType)contentType  withSource:(NSString*)source withSourceDevice:(NSNumber*)sourceDevice withTimestamp:(NSDate*) timestamp;
@end
