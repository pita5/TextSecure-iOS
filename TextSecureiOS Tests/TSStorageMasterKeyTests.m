//
//  TSStorageMasterKeyTests.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSStorageMasterKey.h"
#import "TSStorageError.h"
#import "KeychainWrapper.h"
#import "Constants.h"


@interface TSStorageMasterKeyTests : XCTestCase

@end

static NSString *masterPw = @"1234test";


@implementation TSStorageMasterKeyTests

- (void)setUp
{
    [super setUp];
    [TSStorageMasterKey eraseStorageMasterKey];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


- (void)testCreate
{
    NSError *error = nil;
    XCTAssertFalse([TSStorageMasterKey wasStorageMasterKeyCreated], @"wrong default preference");
    
    NSData *masterKey = [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:&error];
    XCTAssertNotNil(masterKey, @"master storage key creation returned nil");
    XCTAssertNil(error, @"master storage key creation returned an error");
    XCTAssertTrue([TSStorageMasterKey wasStorageMasterKeyCreated], @"master storage key creation did not update preferences");
}

- (void)testCreateAndOverwrite
{
    NSError *error = nil;
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:&error];
    NSData *masterKey = [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:&error];

    XCTAssertNotNil(error, @"master storage key overwrite did not return an error");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"master storage key overwrite returned an unexcpected error");
    XCTAssertEqual([error code], TSStorageErrorStorageKeyAlreadyCreated, @"master storage key overwrite returned an unexcpected error");
    XCTAssertNil(masterKey, @"master storage key overwrite returned an unexcpected error");
}

- (void)testUnlock
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:masterPw error:&error];
    XCTAssertNotNil(masterKey, @"master storage key unlocking returned nil");
    XCTAssertNil(error, @"master storage key unlocking returned an error");
}

- (void)testUnlockWithWrongPassword
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:@"wrongpassword" error:&error];
    
    XCTAssertNotNil(error, @"master storage key was unlocked with an invalid password");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"master storage key unlocking returned an unexpected error");
    XCTAssertEqual([error code], TSStorageErrorInvalidPassword, @"master storage key unlocking returned an unexpected error");
    XCTAssertNil(masterKey, @"master storage key was unlocked with an invalid password");
}

- (void)testUnlockBeforeCreation
{
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:@"wrongpassword" error:&error];
    
    XCTAssertNotNil(error, @"master storage key was unlocked before creation");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"master storage key unlocking returned an unexpected error");
    XCTAssertEqual([error code], TSStorageErrorStorageKeyNotCreated, @"master storage key unlocking returned an unexpected error");
    XCTAssertNil(masterKey, @"master storage key was unlocked before creation");
}

- (void)testGetBeforeCreation
{
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey getStorageMasterKeyWithError:&error];
    
    XCTAssertNotNil(error, @"master storage key was unlocked before creation");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"master storage key unlocking returned an unexpected error");
    XCTAssertEqual([error code], TSStorageErrorStorageKeyNotCreated, @"master storage key unlocking returned an unexpected error");
    XCTAssertNil(masterKey, @"master storage key was unlocked before creation");
}

- (void)testLock
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    [TSStorageMasterKey lockStorageMasterKey];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey getStorageMasterKeyWithError:&error];
    
    XCTAssertNotNil(error, @"master storage key locking failed");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"master storage key unlocking returned an unexpected error");
    XCTAssertEqual([error code], TSStorageErrorStorageKeyLocked, @"master storage key unlocking returned an unexpected error");
    
    XCTAssertTrue([TSStorageMasterKey isStorageMasterKeyLocked],@"master storage key locking failed");
    XCTAssertNil(masterKey, @"master storage key locking failed");
}


- (void)testUnlockWithDeletedKeychain
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    [TSStorageMasterKey lockStorageMasterKey];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:encryptedMasterSecretKeyStorageId];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:masterPw error:&error];
    
    XCTAssertNotNil(error, @"master storage key locking failed");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"master storage key was unlocked with deleted keychain");
    XCTAssertEqual([error code], TSStorageErrorStorageKeyCorrupted, @"master storage key was unlocked with deleted keychain");
    XCTAssertNil(masterKey, @"master storage key was unlocked with deleted keychain");
}


- (void)testErase
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    [TSStorageMasterKey eraseStorageMasterKey];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:masterPw error:&error];
    
    XCTAssertNil(masterKey, @"master storage key deletion failed");
    XCTAssertNotNil(error, @"master storage key deletion failed");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"master storage key deletion failed");
    XCTAssertEqual([error code], TSStorageErrorStorageKeyNotCreated, @"master storage key deletion failed");
}




@end
