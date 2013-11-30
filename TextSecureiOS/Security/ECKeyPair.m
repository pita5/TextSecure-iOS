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

/*

 Example generation and usage
 ECKeyPair* myKeys = [ECKeyPair createAndGeneratePublicPrivatePair:0];
 ECKeyPair* theirKeys = [ECKeyPair createAndGeneratePublicPrivatePair:1];
 
 NSLog(@"my shared secret %@",[myKeys getSharedSecret:theirKeys.publicKey]);
 NSLog(@"their shared secret %@",[theirKeys getSharedSecret:myKeys.publicKey]);
 */


- (id)init {
#warning this class should be refactored to not store strings but bytes for speed
#warning for Android interoperability (and conforming to protocol) we will need to add leading byte of 0x05 to keys prior to sending/remove before using
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
  /* generate private key */
  NSMutableData *randomBytes = [Cryptography  generateRandomBytes:32];
  unsigned char* mysecret = (unsigned char*) [randomBytes bytes];
  mysecret[0] &= 248;
  mysecret[31] &= 127;
  mysecret[31] |= 64;

  /* generate public key */
  unsigned char  mypublic[32];

  static const uint8_t basepoint[32] = {9};
  curve25519_donna(mypublic, mysecret, basepoint);
  
  /* storing in class */
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

-(NSString*) getSharedSecret:(NSString*)theirPublicKey {
  /* computing shared secret based on this class' private key*/
  unsigned char* mysecret = (unsigned char*)[[NSData dataFromBase64String:self.privateKey] bytes];
  unsigned char* theirpublic = (unsigned char*)[[NSData dataFromBase64String:theirPublicKey] bytes];
  uint8_t my_shared_key[32];
  curve25519_donna(my_shared_key, mysecret, theirpublic);
  return [[NSData dataWithBytes:my_shared_key length:32] base64EncodedString];
}

+(ECKeyPair*) createAndGeneratePublicPrivatePair:(int)prekeyId {
  ECKeyPair* pair =[[ECKeyPair alloc] init];
  pair.prekeyId = prekeyId;
  [pair generateKeys];
  return pair;
}





@end
