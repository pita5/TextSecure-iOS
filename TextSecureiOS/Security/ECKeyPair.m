//
//  ECKeyPair.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "ECKeyPair.h"
#include <openssl/obj_mac.h>


@implementation ECKeyPair

-(id) init {
  if(self==[super init]) {
    self.key=[self generateNISTp256ECCKeyPair];
  }
  return  self;
}

-(id) initWithKey:(EC_KEY*)ecKey{
  if(self==[super init]) {
    self.key=ecKey;
  }
  return  self;
}

-(NSString*) getSerializedPrivateKey{
  int len = i2d_ECPrivateKey(self.key,NULL);
  unsigned char *privateKeyBuf = OPENSSL_malloc(len);
  memset(privateKeyBuf, 0, len);
  int ret = i2d_ECPrivateKey(self.key,&privateKeyBuf);
  if (!ret){
    return nil;
  }
  else {
    return [NSString stringWithFormat:@"%s",privateKeyBuf];
  }
}

-(NSString*)getSerializedPublicKey {
  int len = i2o_ECPublicKey(self.key,NULL);
  unsigned char *publicKeyBuf = OPENSSL_malloc(len);
  memset(publicKeyBuf, 0, len);
  int ret = i2o_ECPublicKey(self.key,&publicKeyBuf);
  if (!ret){
    return nil;
  }
  else {
    return [NSString stringWithFormat:@"%s",publicKeyBuf];
  }
}

- (EC_KEY*) generateNISTp256ECCKeyPair {
  EC_KEY *ecKey = EC_KEY_new();
  EC_GROUP *group = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1);
  EC_KEY_set_group(ecKey, group);
  EC_GROUP_set_point_conversion_form(group, POINT_CONVERSION_COMPRESSED);
  EC_KEY_generate_key(ecKey);
  return ecKey;
}



@end
