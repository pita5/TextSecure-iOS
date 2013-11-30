//
//  ECKeyPair.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
extern void curve25519_donna(unsigned char *output, const unsigned char *a,
                             const unsigned char *b);
@interface ECKeyPair : NSObject {
 
}
@property (nonatomic) int prekeyId;
// Base 64 serialized string, later store bytes directly for speed
@property (nonatomic,strong) NSString* publicKey;
@property (nonatomic,strong) NSString* privateKey;

- (id)initWithPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey prekeyId:(int)prekeyId;
- (id)initWithPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey;
- (id)initWithPublicKey:(NSString *)publicKey;
- (BOOL)generateKeys;
- (BOOL)setPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey;
+(ECKeyPair*) createAndGeneratePublicPrivatePair:(int)prekeyId;
@end
