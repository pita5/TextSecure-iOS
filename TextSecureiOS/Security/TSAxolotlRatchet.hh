//
//  TSAxolotlRatchet.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSSession;
@class TSPrekey;
@class TSWhisperMessage;
@class TSMessage;
@class TSContact;
@class TSEncryptedWhisperMessage;

@interface TSAxolotlRatchet : NSObject

#pragma mark Encryption methods

+ (TSEncryptedWhisperMessage*)encryptMessage:(TSMessage*)message withSession:(TSSession*)session;

#pragma mark DecryptionMethods
+ (TSMessage*)decryptMessage:(TSEncryptedWhisperMessage*)message withSession:(TSSession*)session;
+ (TSMessage*)messageWithWhisperMessage:(TSEncryptedWhisperMessage*)message fromContact:(TSContact*)contact;

#pragma mark Identity
+ (TSECKeyPair*)myIdentityKey;


@end


