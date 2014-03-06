//
//  TSAxolotlRatchet.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TSPrekey;
@class TSWhisperMessage;
@class TSMessage;
@class TSContact;
@class TSEncryptedWhisperMessage;

@interface TSAxolotlRatchet : NSObject

// Method for outgoing messages
+ (BOOL) needsPrekey:(TSContact*)contact;
+ (TSWhisperMessage*)encryptedMessage:(TSMessage*)outgoingMessage deviceId:(int)deviceId preKey:(TSPrekey*)prekey;
+ (TSWhisperMessage*)encryptedMessage:(TSMessage*)outgoingMessage deviceId:(int)deviceId;

// Method for incoming messages
+ (TSMessage*)messageWithWhisperMessage:(TSEncryptedWhisperMessage*)message;

#pragma mark Identity
+ (TSECKeyPair*)myIdentityKey;


@end


