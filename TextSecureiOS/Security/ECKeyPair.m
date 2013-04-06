//
//  ECKeyPair.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 4/5/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "ECKeyPair.h"
@implementation ECKeyPair

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
    NSLog(@"Public key %s",publicKeyBuf);
    return [NSString stringWithFormat:@"%s",publicKeyBuf];
  }
}
@end
