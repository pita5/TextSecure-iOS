//
//  TSStorageMasterKeyTests.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSStorageMasterKey.h"
#import "TSEncryptedDatabaseError.h"
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
    XCTAssertFalse([TSStorageMasterKey wasStorageMasterKeyCreated], @"wrong default preference");
    
    NSData *masterKey = [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw];
    XCTAssertNotNil(masterKey, @"master storage key creation returned nil");
    XCTAssertTrue([TSStorageMasterKey wasStorageMasterKeyCreated], @"master storage key creation did not update preferences");
}


- (void)testUnlock
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:masterPw error:&error];
    XCTAssertNotNil(masterKey, @"master storage key unlocking returned nil");
    XCTAssertNil(error, @"master storage key unlocking returned an error");
}

- (void)testUnlockWithWrongPassword
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:@"wrongpassword" error:&error];
    
    XCTAssertTrue([[error domain] isEqualToString:TSEncryptedDatabaseErrorDomain], @"master storage key unlocking returned an unexpected error");
    XCTAssertEqual([error code], InvalidPassword, @"master storage key unlocking returned an unexpected error");
    XCTAssertNil(masterKey, @"master storage key was unlocked with an invalid password");
}


- (void)testLock
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw];
    [TSStorageMasterKey lockStorageMasterKey];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey getStorageMasterKeyWithError:&error];
    // TODO: check for the exact error
    XCTAssertTrue([TSStorageMasterKey isStorageMasterKeyLocked],@"master storage key locking failed");
    XCTAssertNil(masterKey, @"master storage key locking failed");
    XCTAssertNotNil(error, @"master storage key locking failed");
}


- (void)testUnlockWithDeletedKeychain
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw];
    [TSStorageMasterKey lockStorageMasterKey];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:encryptedMasterSecretKeyStorageId];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:masterPw error:&error];
    XCTAssertTrue([[error domain] isEqualToString:TSEncryptedDatabaseErrorDomain], @"master storage key was unlocked with deleted keychain");
    XCTAssertEqual([error code], keychainError, @"master storage key was unlocked with deleted keychain");
    XCTAssertNil(masterKey, @"master storage key was unlocked with deleted keychain");
}


- (void)testErase
{
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw];
    [TSStorageMasterKey eraseStorageMasterKey];
    
    NSError *error = nil;
    NSData *masterKey = [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:masterPw error:&error];
    XCTAssertNil(masterKey, @"master storage key deletion failed");
    XCTAssertNotNil(error, @"master storage key deletion failed");
}




@end
