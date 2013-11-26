//
//  EncryptedDatabase_Tests.m
//  EncryptedDatabase Tests
//
//  Created by Alban Diquet on 11/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EncryptedDatabase.h"
#import "Cryptography.h"
#import "KeychainWrapper.h"
#import "NSData+Base64.h"
#import "Constants.h"


static NSString *dbPw = @"1234test";


@interface EncryptedDatabase_Tests : XCTestCase

@end

@implementation EncryptedDatabase_Tests

- (void)setUp
{
    [super setUp];
    // Remove any existing DB
    [EncryptedDatabase databaseErase];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}



- (void)testDatabaseErase
{
    NSError *error = nil;
    [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [EncryptedDatabase databaseErase];
    EncryptedDatabase *encDb = [EncryptedDatabase databaseUnlockWithPassword:dbPw error:&error];
    XCTAssertNotNil(error, @"database was unlocked after being erased");
    XCTAssertNil(encDb, @"database was unlocked after being erased");
}


- (void)testDatabaseCreate
{
    NSError *error = nil;
    EncryptedDatabase *encDb = [EncryptedDatabase databaseCreateWithPassword:dbPw error:&error];
    XCTAssertNil(error, @"database creation returned an error");
    XCTAssertNotNil(encDb, @"database creation failed");
}


- (void)testDatabaseCreateAndOverwrite
{
    NSError *error = nil;
    [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    EncryptedDatabase *encDb = [EncryptedDatabase databaseCreateWithPassword:dbPw error:&error];
    // TODO: Look at the actual error code
    XCTAssertNil(encDb, @"database overwrite did not fail");
    XCTAssertNotNil(error, @"database overwrite did not return an error");
}


- (void)testDatabaseAfterCreate
{
    [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    EncryptedDatabase *encDb = [EncryptedDatabase database];
    XCTAssertNotNil(encDb, @"could not get a reference to the database");
}


- (void)testDatabaseLock
{
    EncryptedDatabase *encDb = [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [EncryptedDatabase databaseLock];
    XCTAssertThrows([[EncryptedDatabase database] getIdentityKey], @"database was still accessible after getting locked");
    XCTAssertNil(encDb.dbQueue, @"database was still accessible after getting locked");
}


- (void)testDatabaseIsLocked
{
    EncryptedDatabase *encDb = [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    XCTAssertFalse([encDb isLocked], @"database was in locked state after creation");
    [EncryptedDatabase databaseLock];
    XCTAssertTrue([encDb isLocked], @"database was in unlocked state after getting locked");
}


- (void)testDatabaseUnlock
{
    NSError *error = nil;
    EncryptedDatabase *encDb = [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [EncryptedDatabase databaseLock];
    
    encDb = [EncryptedDatabase databaseUnlockWithPassword:dbPw error:&error];
    XCTAssertNotNil(encDb, @"valid password did not unlock the database");
    XCTAssertNil(error, @"valid password returned an error");
}


- (void)testDatabaseUnlockWithWrongPassword
{
    NSError *error = nil;
    [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [EncryptedDatabase databaseLock];
    
    EncryptedDatabase *encDb = [EncryptedDatabase databaseUnlockWithPassword:@"wrongpw" error:&error];
    XCTAssertNil(encDb, @"wrong password unlocked the database");
    // TODO: Look at the actual error code
    XCTAssertNotNil(error, @"wrong password did not return an error");
}


- (void)testDatabaseUnlockWithDeletedKeychain
{
    [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [EncryptedDatabase databaseLock];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:encryptedMasterSecretKeyStorageId];
    XCTAssertThrows([EncryptedDatabase databaseUnlockWithPassword:dbPw error:nil], @"database was unlocked with deleted keychain");
}


- (void)testDatabaseUnlockWithCorruptedKeychain
{
    [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [EncryptedDatabase databaseLock];
    
    NSData *encryptedDbMasterKey = [Cryptography AES256Encryption:[Cryptography generateRandomBytes:36] withPassword:dbPw];
    [KeychainWrapper createKeychainValue:[encryptedDbMasterKey base64EncodedString] forIdentifier:encryptedMasterSecretKeyStorageId];
    XCTAssertThrows([EncryptedDatabase databaseUnlockWithPassword:dbPw error:nil], @"database was unlocked with corrupted keychain");
}


- (void)testDatabaseWasCreated
{
    [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    XCTAssertTrue([EncryptedDatabase databaseWasCreated], @"preference was not updated after creating database");
}


- (void)testDatabaseWasCreatedAfterErase
{
    [EncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [EncryptedDatabase databaseErase];
    XCTAssertFalse([EncryptedDatabase databaseWasCreated], @"preference was not updated after erasing database");
}


@end
