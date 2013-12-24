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
#include <CommonCrypto/CommonHMAC.h>

#import "NSData+Conversion.h"
#import "KeychainWrapper.h"
#import "Constants.h"
#import <RNCryptor/RNEncryptor.h>
#import <RNCryptor/RNDecryptor.h>

#include "NSString+Conversion.h"
#include "NSData+Base64.h"
#import "FilePath.h"


@implementation Cryptography


#pragma mark random bytes methods
+(NSMutableData*) generateRandomBytes:(int)numberBytes {
  /* used to generate db master key, and to generate signaling key, both at install */
  NSMutableData* randomBytes = [NSMutableData dataWithLength:numberBytes];
  int err = 0;
  err = SecRandomCopyBytes(kSecRandomDefault,numberBytes,[randomBytes mutableBytes]);
  if(err != noErr) {
    @throw [NSException exceptionWithName:@"random problem" reason:@"problem generating the random " userInfo:nil];
  }
  return randomBytes;
}




#pragma mark SHA1 methods
+(NSString*)truncatedSHA1Base64EncodedWithoutPadding:(NSString*)string{
  /* used by TSContactManager to send hashed/truncated contact list to server */
  NSMutableData *hashData = [NSMutableData dataWithLength:20];
  CC_SHA1([[string dataUsingEncoding:NSUTF8StringEncoding] bytes], [[string dataUsingEncoding:NSUTF8StringEncoding] length], [hashData mutableBytes]);
  NSData *truncatedData = [hashData subdataWithRange:NSMakeRange(0, 10)];
  
  return [[truncatedData base64EncodedString] stringByReplacingOccurrencesOfString:@"=" withString:@""];
}








@end
