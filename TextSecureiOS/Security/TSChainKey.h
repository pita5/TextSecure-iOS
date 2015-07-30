//
//  TSChainKey.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 02/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSMessageKeys;

@interface TSChainKey : NSObject<NSCoding>

@property int index;
@property(readonly)NSData *key;

- (instancetype)initWithChainKeyWithKey:(NSData*)key index:(int)index;
- (TSMessageKeys*)messageKeys;
- (TSChainKey*)nextChainKey;

@end