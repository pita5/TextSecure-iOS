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
-(instancetype) initWithMessage:(TSWhisperMessage*) message withContentType:(TSWhisperMessageType)contentType  withSource:(NSString*)source withSourceDevice:(NSNumber*)sourceDevice withTimestamp:(NSDate*) timestamp;
@end
