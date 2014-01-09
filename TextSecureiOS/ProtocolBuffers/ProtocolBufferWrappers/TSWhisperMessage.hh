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
@property (nonatomic,strong) NSString* unencryptedMessage; // will not be serialized but used to create the encrypted message
@end
