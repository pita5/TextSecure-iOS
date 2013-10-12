//
//  ECKeyPair.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <openssl/ec.h>

@interface ECKeyPair : NSObject
@property (nonatomic) EC_KEY* key;
-(id) initWithKey:(EC_KEY*) ecKey;
-(NSString*) getSerializedPrivateKey;
-(NSString*)getSerializedPublicKey;
- (EC_KEY*) generateNISTp256ECCKeyPair;
@end
