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

/**
 *  The encrypt method of the Ratchet does provide a convenient method to encrypt a message.
 *
 *  @param message A TSMessageOutgoing that contains the plaintext to encrypt.
 *  @param session The session used for ratcheting.
 *
 *  @return An encrypted protocol-buffer encoded TSEncryptedWhisperMessage or TSPrekeyWhisperMessage if it's the first message to be sent.
 */

+ (TSEncryptedWhisperMessage*)encryptMessage:(TSMessage*)message withSession:(TSSession*)session;

#pragma mark DecryptionMethods

/**
 *  Reverse operation of the encrypt method.
 *
 *  @param message A protocol buffer object of type TSEncryptedWhisperMessage or TSPrekeyWhisperMessage.
 *  @param session The session used for ratcheting.
 *
 *  @return
 */

+ (TSMessage*)decryptWhisperMessage:(TSEncryptedWhisperMessage*)message withSession:(TSSession*)session;

@end