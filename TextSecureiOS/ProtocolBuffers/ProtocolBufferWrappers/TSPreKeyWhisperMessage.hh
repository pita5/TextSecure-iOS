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
@property (nonatomic,strong) NSData* baseKey; // base Curve25519 key exchange ephemeral: A0 in axolotl
@property (nonatomic,strong) NSData* identityKey; //Curve25519 identity key of the sender: A in axolotl
-(id)initWithPreKeyId:(NSNumber*)prekeyId  senderPrekey:(NSData*)prekey senderIdentityKey:(NSData*)identityKey message:(NSData*)messageContents;

+(NSString*) constructFirstMessage:(NSData*)ciphertext theirPrekeyId:(NSNumber*) theirPrekeyId myCurrentEphemeral:(TSECKeyPair*) currentEphemeral myNextEphemeral:(TSECKeyPair*)myNextEphemeral;
@end
