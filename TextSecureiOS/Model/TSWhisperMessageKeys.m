//
//  TSWhisperMessageKeys.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/9/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSWhisperMessageKeys.h"

@implementation TSWhisperMessageKeys

-(id)initWithCipherKey:(NSData*)encryptionKey macKey:(NSData*)hmacKey {
  if(self=[super init] ){
    _cipherKey = encryptionKey;
    _macKey = hmacKey;
  }
  return self;
}
@end
