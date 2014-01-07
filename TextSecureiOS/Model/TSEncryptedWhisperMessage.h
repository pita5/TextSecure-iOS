//
//  TSWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSWhisperMessage.h"
@interface TSEncryptedWhisperMessage : TSWhisperMessage
//optional bytes  ephemeralKey    = 1;
//optional uint32 counter         = 2;
//optional uint32 previousCounter = 3;
//optional bytes  ciphertext      = 4;
//

@property (nonatomic,strong) NSString* ephemeralKey;
@property (nonatomic,strong) NSNumber* counter;
@property (nonatomic,strong) NSNumber* previousCounter;

@end
