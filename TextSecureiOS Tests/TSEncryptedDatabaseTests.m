//
//  TSEncryptedDatabaseTests.m
//  TSEncryptedDatabase Tests
//
//  Created by Alban Diquet on 11/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSEncryptedDatabase.h"
#import "TSEncryptedDatabaseError.h"
#import "TSEncryptedDatabase+Private.h"
#import "Cryptography.h"
#import "KeychainWrapper.h"
#import "ECKeyPair.h"
#import "NSData+Base64.h"
#import "Constants.h"


static NSString *dbPw = @"1234test";


@interface TSEncryptedDatabaseTests : XCTestCase

@end

@implementation TSEncryptedDatabaseTests

- (void)setUp
{
    [super setUp];
    // Remove any existing DB
    [TSEncryptedDatabase databaseErase];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



- (void)testDatabaseErase
{
    NSError *error = nil;
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseErase];
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseUnlockWithPassword:dbPw error:&error];
    XCTAssertTrue([[error domain] isEqualToString:TSEncryptedDatabaseErrorDomain], @"database was unlocked after being erased");
    XCTAssertEqual([error code], NoDbAvailable, @"database was unlocked after being erased");
    XCTAssertNil(encDb, @"database was unlocked after being erased");
}


- (void)testDatabaseCreate
{
    NSError *error = nil;
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:&error];
    XCTAssertNil(error, @"database creation returned an error");
    XCTAssertNotNil(encDb, @"database creation failed");
}

    
- (void)testDatabaseCreateWithPreviousDatabaseRemnants
{
    NSError *error = nil;
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:@"wrongpassword" error:&error];
    
    [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:kDBWasCreatedBool];
    [[NSUserDefaults standardUserDefaults] synchronize];
    XCTAssertFalse([TSEncryptedDatabase databaseWasCreated], @"databaseWasCreated did not return the expected result");
    
    encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:&error];
    XCTAssertNil(error, @"database creation returned an error");
    XCTAssertNotNil(encDb, @"database creation failed");
}


- (void)testDatabaseCreateAndOverwrite
{
    NSError *error = nil;
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:&error];
    
    XCTAssertNil(encDb, @"database overwrite did not fail");
    XCTAssertTrue([[error domain] isEqualToString:TSEncryptedDatabaseErrorDomain], @"database overwrite did not fail");
    XCTAssertEqual([error code], DbAlreadyExists, @"database overwrite did not fail");
}



- (void)testDatabaseAfterCreate
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase database];
    XCTAssertNotNil(encDb, @"could not get a reference to the database");
}


- (void)testDatabaseLock
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
#warning TODO: Add a call to get something out of the DB
    //XCTAssertThrows([[TSEncryptedDatabase database] getIdentityKey], @"database was still accessible after getting locked");
}


- (void)testDatabaseLockBeforeCreate
{
    XCTAssertThrows([TSEncryptedDatabase databaseLock], @"database was locked before getting created");
}

#if 0
#warning TODO: fix the locking mechanism first
- (void)testDatabaseIsLocked
{
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    XCTAssertFalse([encDb isLocked], @"database was in locked state after creation");
    [TSEncryptedDatabase databaseLock];
    XCTAssertTrue([encDb isLocked], @"database was in unlocked state after getting locked");
}
#endif

- (void)testDatabaseUnlock
{
    NSError *error = nil;
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    
    encDb = [TSEncryptedDatabase databaseUnlockWithPassword:dbPw error:&error];
    XCTAssertNotNil(encDb, @"valid password did not unlock the database");
    XCTAssertNil(error, @"valid password returned an error");
}


- (void)testDatabaseUnlockWithWrongPassword
{
    NSError *error = nil;
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseUnlockWithPassword:@"wrongpw" error:&error];
    XCTAssertTrue([[error domain] isEqualToString:TSEncryptedDatabaseErrorDomain], @"database was unlocked after being erased");
    XCTAssertEqual([error code], InvalidPassword, @"database was unlocked after being erased");
    XCTAssertNil(encDb, @"database was unlocked with an invalid password");
}

#if 0
#warning TODO: Fix this once the DB encryption works
- (void)testDatabaseUnlockWithDeletedKeychain
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:encryptedMasterSecretKeyStorageId];
    
    NSError *error = nil;
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseUnlockWithPassword:dbPw error:&error];
    XCTAssertTrue([[error domain] isEqualToString:TSEncryptedDatabaseErrorDomain], @"database was unlocked with deleted keychain");
    XCTAssertEqual([error code], DbWasCorrupted, @"database was unlocked with deleted keychain");
    XCTAssertNil(encDb, @"database was unlocked with deleted keychain");
}


- (void)testDatabaseUnlockWithCorruptedKeychain
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    
    // Replace the master key
    [TSEncryptedDatabase generateDatabaseMasterKeyWithPassword:dbPw];
    
    NSError *error = nil;
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseUnlockWithPassword:dbPw error:&error];
    XCTAssertTrue([[error domain] isEqualToString:TSEncryptedDatabaseErrorDomain], @"database was unlocked with corrupted keychain");
    XCTAssertEqual([error code], DbWasCorrupted, @"database was unlocked with corrupted keychain");
    XCTAssertNil(encDb, @"database was unlocked with corrupted keychain");
}
#endif

- (void)testDatabaseWasCreated
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    XCTAssertTrue([TSEncryptedDatabase databaseWasCreated], @"preference was not updated after creating database");
}


- (void)testDatabaseWasCreatedAfterErase
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseErase];
    XCTAssertFalse([TSEncryptedDatabase databaseWasCreated], @"preference was not updated after erasing database");
}


@end
