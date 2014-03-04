//
//  RKCK.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/15/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSSession.h"

@class TSECKeyPair;

@interface MKCK : NSObject
@property (nonatomic,strong) NSData* MK;
@property (nonatomic,strong) NSData* CK;
+(instancetype) initWithData:(NSData*)data;
@end


@interface RKCK : NSObject

@property (nonatomic,strong) NSData* RK;
@property (nonatomic,strong) NSData* CK;

+(instancetype) initWithData:(NSData*)data;


-(RKCK*) createChainWithNewEphemeral:(TSECKeyPair*)myEphemeral fromTheirProvideEphemeral:(NSData*)theirPublicEphemeral;
//+(RKCK*) currentSendingChain:(TSSession*)thread;
//+(RKCK*) currentReceivingChain:(TSSession*)thread;
//-(void) saveReceivingChainOnThread:(TSSession*)thread withTheirEphemeral:(NSData*)ephemeral;
//-(void) saveSendingChainOnThread:(TSSession*)thread withMyNewEphemeral:(TSECKeyPair *)ephemeral;

@end