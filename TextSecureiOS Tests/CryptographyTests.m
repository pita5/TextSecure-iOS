//
//  CryptographyTests.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/19/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Cryptography.h"
#import <RNCryptor/RNEncryptor.h>
#import <RNCryptor/RNDecryptor.h>
@interface CryptographyTests : XCTestCase

@end


#if 0
#warning this is out of date.

@implementation CryptographyTests
-(void) testAES256RNEncryption {
  // we are going to want to use kCCModeCTR instead of kCCModeCBC... may need to change settings as well.
  NSData *data = [@"hello world here is some much longer text in fact it is a paragraph of text omgz it is awesome hello world here is some much longer text in fact it is a paragraph of text omgz it is awesomehello world here is some much longer text in fact it is a paragraph of text omgz it is awesome ello world here is some much longer text in fact it is a paragraph of text omgz it is awesome  hello world here is some much longer text in fact it is a paragraph of text omgz it is awesome" dataUsingEncoding:NSUTF8StringEncoding];
  NSError *error;
  NSString *password = @"good password";
  NSData *encryptedData = [RNEncryptor encryptData:data
                                      withSettings:kRNCryptorAES256Settings
                                          password:password
                                             error:&error];
  NSData *decryptedData  = [RNDecryptor decryptData:encryptedData
                                       withPassword:password
                                              error:&error];
  XCTAssertEqualObjects(data, decryptedData, @"encrypted data should equal decrypted data");
}

-(void)  testSHA1 {
  NSLog(@"SHA1 %@",[Cryptography computeSHA1DigestForString:@""]);
  XCTAssertEqualObjects([Cryptography computeSHA1DigestForString:@""],@"da39a3ee5e6b4b0d3255bfef95601890afd80709",@"Sha1 of the empty string wrong.");
}

/*
-(void) testAuthenticationTokenGenerationAndStorage {
  NSString *authToken=[Cryptography generateAndStoreNewAccountAuthenticationToken];
  STAssertEqualObjects([Cryptography getAuthenticationToken],authToken,@"generated authentication token should be the one that was stored");
  NSString *newAuthToken=[Cryptography generateAndStoreNewAccountAuthenticationToken];
  //STAssertNotEqualObjects(newAuthToken,authToken,@"new auth token generated should be different than old");
  STAssertEqualObjects([Cryptography getAuthenticationToken],newAuthToken,@"newly generated authentication token should be the one that was stored");
  // TODO: Assert auth token meets specs.
}
 */

-(void)testComputeMAC {
  for (int i=0;i<20;i++) {
    NSData *hashValue = [Cryptography computeMACDigestForString:@"+41799624499" withSeed:[NSString stringWithFormat:@"%d",i]];
    NSData *desiredValue = [[NSData alloc] initWithContentsOfFile:[NSString stringWithFormat:@"HMAC%d.bin",i]];
    XCTAssertEqualObjects(hashValue, desiredValue, @"HMAC value not equal to that expected");
  }
}

/*
-(void) testGenerateNISTp256ECCKeyPair {
  [Cryptography generateNISTp256ECCKeyPair];
  
}
 */
@end

#endif