//
//  TSPrekeyWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSWhisperMessage.h"
@interface TSPreKeyWhisperMessage : TSWhisperMessage
@property (nonatomic,strong) NSNumber* preKeyId;
@property (nonatomic,strong) NSString* baseKey;
@property (nonatomic,strong) NSString* identityKey;
//optional uint32 preKeyId    = 1;
//optional bytes  baseKey     = 2;
//optional bytes  identityKey = 3;
//optional bytes  message     = 4;
@end
