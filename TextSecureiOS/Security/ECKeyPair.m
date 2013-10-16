//
//  ECKeyPair.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "ECKeyPair.h"
#include <openssl/obj_mac.h>
#include <openssl/evp.h>
#include "NSData+Base64.h"


@implementation ECKeyPair

- (id)init {
	if (![super init]) {
		return nil;
  }
	curveType = NID_X9_62_prime256v1;
	return self;
}


- (id)initWithPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey {
	if (![self init]) {
		return nil;
  }
	if (![self setPublicKey:publicKey privateKey:privateKey]) {
  	return nil;
  }
	return self;
}

- (id)initWithPublicKey:(NSString *)publicKey {
	return [self initWithPublicKey:publicKey privateKey:nil];
}



- (BOOL)generateKeys {
	if (ecKey) {
		EC_KEY_free(ecKey);
  }
  ecKey = EC_KEY_new();
	if (!ecKey) {
		return NO;
  }
  EC_GROUP *group = EC_GROUP_new_by_curve_name(curveType);
  if (!group) {
		return NO;
  }
  EC_KEY_set_group(ecKey, group);
  EC_GROUP_set_point_conversion_form(group, POINT_CONVERSION_COMPRESSED);
  return EC_KEY_generate_key(ecKey);
  
}

- (BOOL)setPublicKey:(NSString *)publicKey privateKey:(NSString *)privateKey {
	if (ecKey) {
		EC_KEY_free(ecKey);
  }
  ecKey = EC_KEY_new_by_curve_name(curveType);
	if (ecKey == NULL) {
		return NO;
  }
  
	NSData *publicKeyData = [NSData dataFromBase64String:publicKey];
	const unsigned char *pubBytes = [publicKeyData bytes];
	ecKey = o2i_ECPublicKey(&ecKey, &pubBytes, [publicKeyData length]);
	if (ecKey == NULL) {
		return NO;
  }
	if (privateKey) {
		NSData *privateKeyData = [NSData dataFromBase64String:privateKey];
		const unsigned char *privBytes = [privateKeyData bytes];
		ecKey = d2i_ECPrivateKey(&ecKey, &privBytes, [privateKeyData length]);
		if (ecKey == NULL) {
			return NO;
    }
	}
	return (EC_KEY_check_key(ecKey));
}




- (NSString *)publicKey {
	unsigned char *bytes = NULL;
	int length = i2o_ECPublicKey(ecKey, &bytes);
	return [[NSData dataWithBytesNoCopy:bytes length:length] base64Encoding];
}

- (NSString *)privateKey {
	unsigned char *bytes = NULL;
	int length = i2d_ECPrivateKey(ecKey, &bytes);
	return [[NSData dataWithBytesNoCopy:bytes length:length] base64Encoding];
}




@end
