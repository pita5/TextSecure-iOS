//
//  TSPrekey.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 05/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPrekey : NSObject<NSCoding>

@property (readonly)int prekeyId;
@property (readonly)NSData *identityKey;
@property (readonly)NSData *ephemeralKey;
@property (readonly)int deviceId;

- (instancetype)initWithIdentityKey:(NSData*)identityKey ephemeral:(NSData*)ephemeral prekeyId:(int)prekeyId;


@end
