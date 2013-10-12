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
#include <openssl/ec.h>
#include <openssl/obj_mac.h>
#include <CommonCrypto/CommonHMAC.h>
#include "NSString+Conversion.h"
#include "NSData+Base64.h"
#include "ECKeyPair.h"
@implementation Cryptography

+(NSString*) generateNewAccountAuthenticationToken {
  NSMutableData* authToken = [NSMutableData dataWithLength:16];
  int err = 0;
  err = SecRandomCopyBytes(kSecRandomDefault,16,[authToken mutableBytes]);
  if(err != noErr) {
    @throw [NSException exceptionWithName:@"authenicationProblem" reason:@"problem generating the random authentication token" userInfo:nil];
  }
  NSString* authTokenPrint = [[NSData dataWithData:authToken] hexadecimalString];
  return authTokenPrint;
}

+(NSString*) generateNewSignalingKeyToken {
   /*The signalingKey is 32 bytes of AES material (256bit AES) and 20 bytes of Hmac key material (HmacSHA1) concatenated into a 52 byte slug that is base64 encoded. */
  NSMutableData* signalingKeyToken = [NSMutableData dataWithLength:52];
  int err = 0;
  err = SecRandomCopyBytes(kSecRandomDefault,52,[signalingKeyToken mutableBytes]);
  if(err != noErr) {
    @throw [NSException exceptionWithName:@"signalingKeyToken" reason:@"problem generating the random signaling key token" userInfo:nil];
  }
  NSString* signalingKeyTokenPrint = [[NSData dataWithData:signalingKeyToken] base64EncodedString];
  return signalingKeyTokenPrint;
}

#pragma mark Authentication Token

+ (BOOL) storeAuthenticationToken:(NSString*)token {
  return [KeychainWrapper createKeychainValue:token forIdentifier:authenticationTokenStorageId];
}


+ (NSString*) getAuthenticationToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:authenticationTokenStorageId];
}

#pragma mark Username (Phone number)

+ (BOOL) storeUsernameToken:(NSString*)token {
  return [KeychainWrapper createKeychainValue:token forIdentifier:usernameTokenStorageId];
}

+ (NSString*) getUsernameToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:usernameTokenStorageId];
}

#pragma mark Authorization Token

+ (NSString*) getAuthorizationToken {
    return [self getAuthorizationTokenFromAuthToken:[Cryptography getAuthenticationToken]];
}

+ (NSString*) getAuthorizationTokenFromAuthToken:(NSString*)authToken{
    return [[NSString stringWithFormat:@"%@:%@",[Cryptography getUsernameToken],[Cryptography getAuthenticationToken]] base64Encoded];
}

#pragma mark SignalingKey

+ (BOOL) storeSignalingKeyToken:(NSString*)token {
    return [KeychainWrapper createKeychainValue:token forIdentifier:signalingTokenStorageId];
}

+ (NSString*) getSignalingKeyToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:signalingTokenStorageId];
}


+ (NSData*)computeMACDigestForString:(NSString*)input withSeed:(NSString*)seed {
  //  void CCHmac(CCHmacAlgorithm algorithm, const void *key, size_t keyLength, const void *data,
  //       size_t dataLength, void *macOut);
  const char *cInput = [input UTF8String];
  const char *cSeed = [seed UTF8String];
  unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA1, cSeed, strlen(cSeed), cInput,strlen(cInput),cHMAC);
  NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
  return HMAC;
  
}
+ (NSString*)computeSHA1DigestForString:(NSString*)input {
  // Here we are taking in our string hash, placing that inside of a C Char Array, then parsing it through the SHA1 encryption method.
  const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
  NSData *data = [NSData dataWithBytes:cstr length:input.length];
  uint8_t digest[CC_SHA1_DIGEST_LENGTH];
  
  CC_SHA1(data.bytes, data.length, digest);
  
  NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
  
  for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
    [output appendFormat:@"%02x", digest[i]];
  }
  
  return output;
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
+ (ECKeyPair*) generateNISTp256ECCKeyPair {
  EC_KEY *ecKey = EC_KEY_new();
  EC_GROUP *group = EC_GROUP_new_by_curve_name(NID_X9_62_prime256v1);
  EC_KEY_set_group(ecKey, group);
  EC_GROUP_set_point_conversion_form(group, POINT_CONVERSION_COMPRESSED);
  EC_KEY_generate_key(ecKey);
  return [[ECKeyPair alloc] initWithKey:ecKey];
}

@end
