//
//  TSChain.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 11/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSChainKey;

@interface TSChain : NSObject

- (instancetype)initWithChainKey:(TSChainKey*)chainKey epehemeral:(NSData*)ephemeral;

@property(readonly)TSChainKey *chainKey;
@property(readonly)NSData *ephemeral;
@property NSMutableArray *messageKeys;

@end
