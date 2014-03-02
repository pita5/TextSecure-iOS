//
//  TSWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSMessage.h"
#import "TSProtocolBufferWrapper.hh"

@interface TSWhisperMessage : TSProtocolBufferWrapper
@property (nonatomic,strong) NSData* message;

//A TextSecure_WhisperMessage is actually

/**
 *  struct {
        opaque version[1];
        opaque WhisperMessage[...];
        opaque mac[8];
    } TextSecure_WhisperMessage;
 */

@end
