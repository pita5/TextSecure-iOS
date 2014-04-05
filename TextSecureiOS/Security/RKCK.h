//
//  RKCK.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/15/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSSession.h"
@class TSChainKey;
@class TSECKeyPair;

@interface RKCK : NSObject

@property (nonatomic,strong) NSData* RK;
@property (nonatomic,strong) TSChainKey* CK;

+(instancetype) initWithRK:(NSData*)rootKey CK:(TSChainKey*)chainKey;
+(instancetype) initWithRootMasterKey:(NSData*)data;

- (RKCK*)createChainWithEphemeral:(TSECKeyPair*)myEphemeral fromTheirProvideEphemeral:(NSData*)theirPublicEphemeral;

@end