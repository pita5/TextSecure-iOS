//
//  TSAxolotlRatchet.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSWhisperMessageKeys.h"
#import "TSECKeyPair.h"
#import "RKCK.h"
#import "TSSession.h"
@class TSMessage;

@interface TSAxolotlRatchet : NSObject

+ (TSWhisperMessageKeys*)decryptionKeysForSession:(TSSession*)session ephemeral:(NSData*)ephemeral counter:(int)counter;
+ (TSWhisperMessageKeys*)encryptionKeyForSession:(TSSession*)session;


@end


