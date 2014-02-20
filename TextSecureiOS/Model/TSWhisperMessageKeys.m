//
//  TSWhisperMessageKeys.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/9/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSWhisperMessageKeys.h"

@implementation TSWhisperMessageKeys
@synthesize cipherKey;
@synthesize macKey;
-(id)initWithCipherKey:(NSData*)encryptionKey macKey:(NSData*)hmacKey {
  if(self=[super init] ) {
    self.cipherKey = encryptionKey;
    self.macKey = hmacKey;
  }
  return self;
}
@end
