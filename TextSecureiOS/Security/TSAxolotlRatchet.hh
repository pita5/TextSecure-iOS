//
//  TSAxolotlRatchet.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSWhisperMessageKeys.h"
#import "TSProtocols.h"
#import "TSECKeyPair.h"
#import "RKCK.h"

@class TSMessage;
@class TSThread;

typedef void(^getNextMessageKeyOnChain)(TSWhisperMessageKeys *messageKeys);
typedef void(^decryptMessageCompletion)(TSMessage *decryptedMessage);

typedef void(^getNewReceiveDecryptKey)(TSECKeyPair *decryptionKey);

@interface TSAxolotlRatchet : NSObject
@property (nonatomic,strong) TSThread *thread;
-(id) initForThread:(TSThread*)thread;
#pragma mark public methods
+(void)receiveMessage:(NSData*)data withCompletion:(decryptMessageCompletion)block;
+(void)sendMessage:(TSMessage*)message onThread:(TSThread*)thread;

@end


