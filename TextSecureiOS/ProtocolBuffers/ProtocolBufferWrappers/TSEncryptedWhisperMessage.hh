//
//  TSWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSWhisperMessage.hh"
#import "WhisperMessage.pb.hh"

@interface TSEncryptedWhisperMessage : TSWhisperMessage

@property (nonatomic,strong) NSData* ephemeralKey;
@property (nonatomic,strong) NSNumber* counter;
@property (nonatomic,strong) NSNumber* previousCounter;
<<<<<<< HEAD

-(id) initWithEphemeralKey:(NSData*)ephemeralKey previousCounter:(NSNumber*)previousCounter counter:(NSNumber*)counter encryptedMessage:(NSData*)ciphertext;
=======
@property (nonatomic,strong) NSData* hmac;
-(id) initWithTextSecure_WhisperMessage:(NSData*) data;
-(NSData*) getTextSecure_WhisperMessage;
-(id) initWithEphemeralKey:(NSData*)ephemeral previousCounter:(NSNumber*)prevCounter counter:(NSNumber*)ctr encryptedMessage:(NSData*)ciphertext forVersion:(NSData*)version withHMAC:(NSData*)mac;
>>>>>>> df1d105e21f317654d353845b5c112a256ccc25d
@end
