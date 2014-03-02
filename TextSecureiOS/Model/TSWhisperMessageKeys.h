//
//  TSWhisperMessageKeys.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/9/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocols.h"
@interface TSWhisperMessageKeys : NSObject

-(id)initWithCipherKey:(NSData*)cipherKey macKey:(NSData*)macKey;

@property(readonly)NSData *cipherKey;
@property(readonly)NSData *macKey;

@end
