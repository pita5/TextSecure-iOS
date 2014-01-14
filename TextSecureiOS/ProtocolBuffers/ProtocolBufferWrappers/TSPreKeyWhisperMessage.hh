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
@property (nonatomic,strong) NSData* recipientPreKey; //not serialized but used in master key derivation
@property (nonatomic,strong) NSData* recipientIdentityKey; // not serialized but used in master key derivation
-(id)initWithPreKeyId:(NSNumber*)prekeyId  recipientPrekey:(NSData*)prekey recipientIdentityKey:(NSData*)identityKey message:(NSData*)messageContents;
@end
