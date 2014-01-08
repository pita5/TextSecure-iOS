//
//  TSPrekeyWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSWhisperMessage.hh"
@interface TSPreKeyWhisperMessage : TSWhisperMessage
@property (nonatomic,strong) NSNumber* preKeyId;
@property (nonatomic,strong) NSData* baseKey;
@property (nonatomic,strong) NSData* identityKey;

@end
