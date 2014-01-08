//
//  TSMissedMessageKeys.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/8/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMissedMessageKeys.h"

@implementation TSMissedMessageKeys

-(id) initWithSkippedMK:(NSData*)mk skippedHKs:(NSData*)hks skippedHKr:(NSData*)hkr {
  if(self=[super init]) {
    self.skippedMK=mk;
    self.skippedHKs=hks;
    self.skippedHKr=hkr;
  }
  return self;
}
@end
