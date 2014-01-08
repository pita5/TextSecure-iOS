//
//  TSMissedMessageKeys.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/8/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSMissedMessageKeys : NSObject
@property (nonatomic,strong) NSData* skippedMK;
@property (nonatomic,strong) NSData* skippedHKs;
@property (nonatomic,strong) NSData* skippedHKr;

-(id) initWithSkippedMK:(NSData*)mk skippedHKs:(NSData*)hks skippedHKr:(NSData*)hkr;
@end
