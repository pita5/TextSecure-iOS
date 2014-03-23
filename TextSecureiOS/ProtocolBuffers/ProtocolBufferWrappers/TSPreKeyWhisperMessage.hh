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

@property (nonatomic,strong) NSNumber* preKeyId;
@property (nonatomic,strong) NSData* baseKey; // base Curve25519 key exchange ephemeral: A0 in axolotl
@property (nonatomic,strong) NSData* identityKey; //Curve25519 identity key of the sender: A in axolotl

-(instancetype)initWithPreKeyId:(NSNumber*)prekeyId  senderPrekey:(NSData*)prekey senderIdentityKey:(NSData*)identityKey message:(NSData*)messageContents forVersion:(NSData*)version;

+(TSPreKeyWhisperMessage *) constructFirstMessage:(NSData*)ciphertext theirPrekeyId:(NSNumber*) theirPrekeyId myCurrentEphemeral:(NSData*) currentEphemeral myNextEphemeral:(NSData*)myNextEphemeral  forVersion:(NSData*)version withHMAC:(NSData*)hmac;

@end
