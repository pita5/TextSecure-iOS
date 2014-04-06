//
//  TSPrekeyWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSEncryptedWhisperMessage.hh"
#import "TSMessagesDatabase.h"

@class TSECKeyPair;

@interface TSPreKeyWhisperMessage : TSWhisperMessage

+(TSPreKeyWhisperMessage *) constructFirstMessage:(NSData*)ciphertext theirPrekeyId:(NSNumber*) theirPrekeyId myCurrentEphemeral:(NSData*) currentEphemeral myNextEphemeral:(NSData*)myNextEphemeral  forVersion:(NSData*)version withHMACKey:(NSData*)hmac;

@end
