//
//  TSMessageKeys.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 09/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSMessageKeys : NSObject

- (instancetype)initWithCipherKey:(NSData*)cipherKey macKey:(NSData*)macKey counter:(int)counter;

@property (readonly)NSData *cipherKey;
@property (readonly)NSData *macKey;
@property (readonly)int counter;

@end
