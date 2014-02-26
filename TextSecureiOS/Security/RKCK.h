//
//  RKCK.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/15/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSECKeyPair;
@class TSThread;

@interface MKCK : NSObject
@property (nonatomic,strong) NSData* MK;
@property (nonatomic,strong) NSData* CK;
+(id) withData:(NSData*)data;

@end


@interface RKCK : NSObject
typedef void(^performSaveOnChainCompletionBlock) (BOOL success);
typedef void(^fetchCurrentSendingChainCompletionBlock) (RKCK* keypair);

@property (nonatomic,strong) NSData* RK;
@property (nonatomic,strong) NSData* CK;
@property (nonatomic,strong) id ephemeral;
+(id) withData:(NSData*)data;
-(RKCK*) createChainWithNewEphemeral:(TSECKeyPair*)myEphemeral fromTheirProvideEphemeral:(NSData*)theirPublicEphemeral;
+(void) currentSendingChain:(TSThread*)thread withCompletionHandler:(fetchCurrentSendingChainCompletionBlock)block;
-(void) saveReceivingChainOnThread:(TSThread*)thread withTheirEphemeral:(NSData*)ephemeral withCompletionHandler:(performSaveOnChainCompletionBlock)block;
-(void) saveSendingChainOnThread:(TSThread*)thread withMyNewEphemeral:(TSECKeyPair *)ephemeral withCompletionHandler:(performSaveOnChainCompletionBlock)block;
@end