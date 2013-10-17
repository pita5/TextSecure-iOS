//
//  ECKeyPair.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <openssl/ec.h>

@interface ECKeyPair : NSObject {
  EC_KEY *ecKey;
  unsigned int curveType;

}
@property (nonatomic) int prekeyId;
- (id)initWithPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey prekeyId:(int)prekeyId;
- (id)initWithPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey;
- (id)initWithPublicKey:(NSString *)publicKey;
- (BOOL)generateKeys;
- (BOOL)setPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey;
- (NSString *)publicKey;
- (NSString *)privateKey;
+(ECKeyPair*) createAndGeneratePublicPrivatePair:(int)prekeyId;
@end
