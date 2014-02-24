//
//  TSAxolotlRatchet.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocols.h"
@class TSMessage;
@class TSThread;
@interface TSAxolotlRatchet : NSObject
@property (nonatomic,strong) TSThread* thread;
-(id) initForThread:(TSThread*)thread;
#pragma mark public methods
+(void)receiveMessage:(NSData*)data;
+(void)sendMessage:(TSMessage*)message onThread:(TSThread*)thread;


@end


