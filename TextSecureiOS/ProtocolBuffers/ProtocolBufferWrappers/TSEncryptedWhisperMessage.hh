//
//  TSWhisperMessage.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSWhisperMessage.hh"

@interface TSEncryptedWhisperMessage : TSWhisperMessage
@property (readonly,nonatomic,strong) NSData* ephemeralKey;
@property (readonly,nonatomic,strong) NSNumber* counter;
@property (readonly,nonatomic,strong) NSNumber* previousCounter;
@property (readonly,nonatomic,strong) NSData* hmac;
@property (readonly,nonatomic,strong) NSData* message;
@property (readonly,nonatomic,strong) NSData* version;
@property (readonly,nonatomic,strong) NSData *protocolData;


-(instancetype) initWithEphemeralKey:(NSData*)ephemeral previousCounter:(NSNumber*)prevCounter counter:(NSNumber*)ctr encryptedMessage:(NSData*)ciphertext forVersion:(NSData*)version HMACKey:(NSData*)hmacKey;

- (BOOL)verifyHMAC:(NSData*)hmacKey;

@end
