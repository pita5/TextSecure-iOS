//
//  TSWhisperMessageKeys.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/9/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocols.h"
@interface TSWhisperMessageKeys : NSObject<AxolotlEphemeralStorageMessagingKeys>

-(id)initWithCipherKey:(NSData*)cipherKey macKey:(NSData*)macKey;

@end
