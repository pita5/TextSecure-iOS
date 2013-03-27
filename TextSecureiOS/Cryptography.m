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


+ (NSString*) retrieveAuthenticationToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:authenticationTokenStorageId];
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


@end
