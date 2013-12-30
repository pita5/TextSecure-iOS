//
//  TSMessagesDatabase.m
//  TSMessagesDatabase Tests
//
//  Created by Alban Diquet on 11/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSMessagesDatabase.h"
#import "TSEncryptedDatabaseError.h"
#import "Cryptography.h"
#import "KeychainWrapper.h"
#import "NSData+Base64.h"
#import "Constants.h"
#import "TSStorageMasterKey.h"

static NSString *dbPw = @"1234test";


@interface TSMessagesDatabaseTests : XCTestCase

@end

@implementation TSMessagesDatabaseTests

- (void)setUp
{
    [super setUp];
    // Remove any existing DB
    [TSMessagesDatabase databaseErase];
    
    
    [TSStorageMasterKey eraseStorageMasterKey];
    [TSStorageMasterKey createStorageMasterKeyWithPassword:dbPw];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [TSStorageMasterKey eraseStorageMasterKey];
}



- (void)testDatabaseCreate
{
    NSError *error = nil;
    
    XCTAssertTrue([TSMessagesDatabase databaseCreateWithError:&error], @"message db creation failed");
    XCTAssertNil(error, @"message db creation returned an error");
}


#if 0
// TODO: Move these tests to TSEncryptedDatabaseTests
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

#if 0
// TODO move these tests to TSStorageMasterKey
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
#endif

@end
