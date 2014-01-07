//
//  TSProtocolManagerForThread.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSMessage;
@class TSThread;
@protocol TSProtocol <NSObject>
-(void) sendMessage:(TSMessage*) message onThread:(TSThread*)thread;
-(NSData*) encryptMessage:(TSMessage*)message onThread:(TSThread*)thread;
-(TSMessage*) decryptMessage:(NSData*)message onThread:(TSThread*)thread;


@end
