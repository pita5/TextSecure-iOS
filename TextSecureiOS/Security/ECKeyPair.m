//
//  ECKeyPair.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "ECKeyPair.h"
#import "Cryptography.h"
#include "NSData+Base64.h"

@implementation ECKeyPair

- (id)init {
	if (![super init]) {
		return nil;
  }
	return self;
}


- (id)initWithPublicKey:(NSString *)pubKey privateKey:(NSString *)privKey prekeyId:(int)prekeyId {
	if (![self initWithPublicKey:pubKey privateKey:privKey]) {
  	return nil;
  }
  self.prekeyId=prekeyId;
	return self;
}

- (id)initWithPublicKey:(NSString *)pubKey privateKey:(NSString *)privKey {
	if (![self init]) {
		return nil;
  }
	if (![self setPublicKey:pubKey privateKey:privKey]) {
  	return nil;
  }
	return self;
}

- (id)initWithPublicKey:(NSString *)pubKey {
	return [self initWithPublicKey:pubKey privateKey:nil];
}



- (BOOL)generateKeys {
  //To generate a private key, generate 32 random bytes and:
  NSMutableData *randomBytes = [Cryptography  generateRandomBytes:32];
  unsigned char* mysecret = (unsigned char*) [randomBytes bytes];
  mysecret[0] &= 248;
  mysecret[31] &= 127;
  mysecret[31] |= 64;

  unsigned char  mypublic[32];
  //To generate the public key, just do
  static const uint8_t basepoint[32] = {9};
  curve25519_donna(mypublic, mysecret, basepoint);
  
  // Now let's go ahead and store these
  NSData* secretData = [NSData dataWithBytes:mysecret length:32];
  NSData* publicData = [NSData dataWithBytes:mypublic length:32];
  
  self.privateKey = [secretData base64EncodedString];
  self.publicKey = [publicData base64EncodedString];
  return YES;
}

- (BOOL)setPublicKey:(NSString *)pubKey privateKey:(NSString *)privKey {
  self.publicKey = pubKey;
  self.privateKey = privKey;
  return YES;
}


+(ECKeyPair*) createAndGeneratePublicPrivatePair:(int)prekeyId {
  ECKeyPair* pair =[[ECKeyPair alloc] init];
  pair.prekeyId = prekeyId;
  [pair generateKeys];
  return pair;
}





@end
