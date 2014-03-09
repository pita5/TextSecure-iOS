//
//  TSMessageKeys.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 09/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessageKeys.h"

@implementation TSMessageKeys

- (instancetype)initWithCipherKey:(NSData*)cipherKey macKey:(NSData*)macKey counter:(int)counter{
    self = [super init];
    if (self) {
        _cipherKey = cipherKey;
        _macKey = macKey;
        _counter = counter;
    }
    
    return self;
}

@end
