//
//  TSChain.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 07/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSChainKey;

@interface TSChain : NSObject

@property TSChainKey *chainKey;
@property int counter;

@end
