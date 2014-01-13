//
//  TSAxolotlRatchet.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocol.h"
@class TSMessage;
@class TSThread;
@interface TSAxolotlRatchet : NSObject

#pragma mark public methods
+(void)processIncomingMessage:(NSData*)data;
+(void)processOutgoingMessage:(TSMessage*)message onThread:(TSThread*)thread ofType:(TSWhisperMessageType) messageType;
#pragma mark private methods

@end
