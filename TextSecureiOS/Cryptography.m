//
//  Cryptography.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "Cryptography.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonHMAC.h>
#import "NSData+Conversion.h"
#import "KeychainWrapper.h"
#import "Constants.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
// Now we can use openssl 
#include <openssl/ec.h>
#include <openssl/obj_mac.h>
#include "NSString+Conversion.h"
@implementation Cryptography

+(NSString*) generateAndStoreNewAccountAuthenticationToken {
  NSMutableData* authToken = [NSMutableData dataWithLength:16];
  int err = 0;
  err = SecRandomCopyBytes(kSecRandomDefault,16,[authToken mutableBytes]);
  if(err != noErr) {
    @throw [NSException exceptionWithName:@"authenicationProblem" reason:@"problem generating the random authentication token" userInfo:nil];
  }
  NSString* authTokenPrint = [[NSData dataWithData:authToken] hexadecimalString];
  [Cryptography storeAuthenticationToken:authTokenPrint];
  return authTokenPrint;
  
}
+ (BOOL) storeAuthenticationToken:(NSString*)token {
  return [KeychainWrapper createKeychainValue:token forIdentifier:authenticationTokenStorageId];
}


+ (NSString*) getAuthenticationToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:authenticationTokenStorageId];
}


+ (BOOL) storeUsernameToken:(NSString*)token {
  return [KeychainWrapper createKeychainValue:token forIdentifier:usernameTokenStorageId];
}


+ (NSString*) getUsernameToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:usernameTokenStorageId];
}

+ (NSString*) getAuthorizationToken {
  return [[NSString stringWithFormat:@"%@:%@",[Cryptography getUsernameToken],[Cryptography getAuthenticationToken]] base64Encoded];
}

+ (NSString*)computeSHA1DigestForString:(NSString*)input {
  // Here we are taking in our string hash, placing that inside of a C Char Array, then parsing it through the SHA1 encryption method.
  // Will be used for 160 bit HMAC (should be 10 char hex)
  const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
  NSData *data = [NSData dataWithBytes:cstr length:input.length];
  uint8_t digest[CC_SHA1_DIGEST_LENGTH];
  
  // This is an iOS5-specific method.
  // It takes in the data, how much data, and then output format, which in this case is an int array.
  CC_SHA1(data.bytes, data.length, digest);
  
  // Setup our Objective-C output.
  NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
  
  // Parse through the CC_SHA1 results (stored inside of digest[]).
  for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
    [output appendFormat:@"%02x", digest[i]];
  }
  
  return output;
}

+(void) testEncryption {
  // we are going to want to use kCCModeCTR instead of kCCModeCBC... may need to change settings as well.
  NSData *data = [@"hello world here is some much longer text in fact it is a paragraph of text omgz it is awesome hello world here is some much longer text in fact it is a paragraph of text omgz it is awesomehello world here is some much longer text in fact it is a paragraph of text omgz it is awesome ello world here is some much longer text in fact it is a paragraph of text omgz it is awesome  hello world here is some much longer text in fact it is a paragraph of text omgz it is awesome" dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error;
  NSData *encryptedData = [RNEncryptor encryptData:data
                                      withSettings:kRNCryptorAES256Settings
                                          password:@"good password"
                                             error:&error];
  NSLog(@"encrypting %@",encryptedData);
  NSData *decryptedData  = [RNDecryptor decryptData:encryptedData
                  withPassword:@"good password"
                  error:&error];
  NSLog(@"decrypting %@",[[NSString alloc] initWithData:decryptedData
                                               encoding:NSUTF8StringEncoding]);
}

+ (void) generateECKeyPairSecurityFramework {
  // This native Security.framework method is unused, as it is not sufficiently documented and we are unable to use point compression. It is included here in case we wish to do comparisons later on. 
  SInt32 iKeySize = 256; // possible key size goes up to 521.
  CFNumberRef keySize = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &iKeySize);
  const void* values[] = {kSecAttrKeyTypeEC, keySize};
  const void* keys[] = {kSecAttrKeyType, kSecAttrKeySizeInBits};
  CFDictionaryRef parameters = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 2, NULL, NULL);
  
  SecKeyRef publicKey, privateKey;
  OSStatus ret = SecKeyGeneratePair(parameters, &publicKey, &privateKey);
  if(ret != errSecSuccess ){
    @throw [NSException exceptionWithName:@"ECGenerationProblem" reason:@"problem generating the EC key" userInfo:nil];
  }
}
+ (void) generateNISTp256ECCKeyPair {
  EC_KEY *ecKey = EC_KEY_new();
  EC_GROUP *group = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1);
  EC_KEY_set_group(ecKey, group);
  EC_GROUP_set_point_conversion_form(group, POINT_CONVERSION_COMPRESSED);
  EC_KEY_generate_key(ecKey);
  const BIGNUM *privateKey = EC_KEY_get0_private_key(ecKey);
  const EC_POINT *publicKey = EC_KEY_get0_public_key(ecKey);
//  
//  int len = i2d_ECPrivateKey(ecKey,NULL);
//  unsigned char *privateKeyBuf = OPENSSL_malloc(len);
//  memset(privateKeyBuf, 0, len);
//  int ret = i2d_ECPrivateKey(ecKey,&privateKeyBuf);
//  if (!ret){
//    NSLog(@"Private key to DER failed\n");
//    return;
//  }
//  else {
//    NSLog(@"Private key %s",privateKeyBuf);
//  }
//  len = i2o_ECPublicKey(ecKey,NULL);
//  unsigned char *publicKeyBuf = OPENSSL_malloc(len);
//  memset(publicKeyBuf, 0, len);
//  ret = i2o_ECPublicKey(ecKey,&publicKeyBuf);
//  if (!ret){
//    NSLog(@"Public key to octed failed\n");
//    return;
//  }
//  else {
//    NSLog(@"Public key %s",publicKeyBuf);
//  }

  NSLog(@"key generation generated");
}

@end
