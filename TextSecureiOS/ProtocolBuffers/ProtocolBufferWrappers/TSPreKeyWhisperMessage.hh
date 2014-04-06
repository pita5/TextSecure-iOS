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
@property (readonly,nonatomic,strong) NSData *protocolData;
@property (readonly,nonatomic,strong) NSData* version;

@property (readonly,nonatomic,strong) NSNumber* preKeyId;
@property (readonly,nonatomic,strong) NSData* baseKey; // base Curve25519 key exchange ephemeral: A0 in axolotl
@property (readonly,nonatomic,strong) NSData* identityKey; //Curve25519 identity key of the sender: A in axolotl
@property (readonly,nonatomic,strong) NSData* message;

+(TSPreKeyWhisperMessage *) constructFirstMessage:(NSData*)ciphertext theirPrekeyId:(NSNumber*) theirPrekeyId myCurrentEphemeral:(NSData*) currentEphemeral myNextEphemeral:(NSData*)myNextEphemeral  forVersion:(NSData*)version withHMACKey:(NSData*)hmac;

@end
