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
@property (nonatomic,strong) NSData* ephemeralKey;
@property (nonatomic,strong) NSNumber* counter;
@property (nonatomic,strong) NSNumber* previousCounter;
@property (nonatomic,strong) NSData* mac;
-(id) initWithEphemeralKey:(NSData*)ephemeralKey previousCounter:(NSNumber*)previousCounter counter:(NSNumber*)counter encryptedMessage:(NSData*)ciphertext withVersion:(NSData*)version withMac:(NSData*)mac;
@end
