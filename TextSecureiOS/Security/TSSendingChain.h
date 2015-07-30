//
//  TSSendingChain.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 13/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSChainKey;
@class TSECKeyPair;

@interface TSSendingChain : NSObject<NSCoding>

- (instancetype)initWithChainKey:(TSChainKey*)chainKey ephemeral:(TSECKeyPair*)ephemeral;

@property(readonly)TSChainKey *chainKey;
@property(readonly)TSECKeyPair *ephemeral;


@end
