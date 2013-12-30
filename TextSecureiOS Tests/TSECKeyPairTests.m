//
//  TSECKeyPairTests.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSECKeyPair.h"


@interface TSECKeyPairTests : XCTestCase

@end

@implementation TSECKeyPairTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


- (void)testGenerateKeyPair
{
    TSECKeyPair *keyPair = [TSECKeyPair keyPairGenerateWithPreKeyId:1];
    XCTAssertNotNil(keyPair, @"Key pair generation returned a nil key pair.");
    
    NSData *publicKey = [keyPair getPublicKey];
    XCTAssertNotNil(publicKey, @"Key pair generation returned a nil public key.");
}


- (void)testGenerateSharedSecret
{
    TSECKeyPair *keyPair1 = [TSECKeyPair keyPairGenerateWithPreKeyId:1];
    TSECKeyPair *keyPair2 = [TSECKeyPair keyPairGenerateWithPreKeyId:2];
    
    NSData *publicKey = [keyPair1 getPublicKey];
    NSData *sharedSecret = [keyPair2 generateSharedSecretFromPublicKey:publicKey];
    XCTAssertNotNil(sharedSecret, @"Shared secret generation returned a nil shared secret.");
}


- (void)testSerialization
{
    TSECKeyPair *keyPair1 = [TSECKeyPair keyPairGenerateWithPreKeyId:1];
    NSData *serializedKeyPair = [NSKeyedArchiver archivedDataWithRootObject:keyPair1];
    XCTAssertNotNil(serializedKeyPair, @"Key pair serialization returned a nil data object.");
    
    TSECKeyPair *keyPair2 = [NSKeyedUnarchiver unarchiveObjectWithData:serializedKeyPair];
    XCTAssertNotNil(keyPair2, @"Key pair de-serialization returned a nil key pair.");
    
    XCTAssertEqualObjects([keyPair1 getPublicKey], [keyPair2 getPublicKey], @"Key pair de-serialization returned a different public key");
}


@end
