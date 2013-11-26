//
//  EncryptedDatabase_Tests.m
//  EncryptedDatabase Tests
//
//  Created by Alban Diquet on 11/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSEncryptedDatabase.h"
#import "Cryptography.h"
#import "KeychainWrapper.h"
#import "NSData+Base64.h"
#import "Constants.h"


static NSString *dbPw = @"1234test";


@interface TSEncryptedDatabase_Tests : XCTestCase

@end

@implementation TSEncryptedDatabase_Tests

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
    XCTAssertNotNil(error, @"database was unlocked after being erased");
    XCTAssertNil(encDb, @"database was unlocked after being erased");
}


- (void)testDatabaseCreate
{
    NSError *error = nil;
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:&error];
    XCTAssertNil(error, @"database creation returned an error");
    XCTAssertNotNil(encDb, @"database creation failed");
    
    XCTAssertNotNil([encDb getPersonalPrekeys], @"could not retrieve user keys");
    XCTAssertNotNil([encDb getIdentityKey], @"could not retrieve user keys");
}


- (void)testDatabaseCreateAndOverwrite
{
    NSError *error = nil;
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:&error];
    // TODO: Look at the actual error code
    XCTAssertNil(encDb, @"database overwrite did not fail");
    XCTAssertNotNil(error, @"database overwrite did not return an error");
}


- (void)testDatabaseAfterCreate
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase database];
    XCTAssertNotNil(encDb, @"could not get a reference to the database");
}


- (void)testDatabaseLock
{
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    XCTAssertThrows([[TSEncryptedDatabase database] getIdentityKey], @"database was still accessible after getting locked");
    XCTAssertNil(encDb.dbQueue, @"database was still accessible after getting locked");
}


- (void)testDatabaseIsLocked
{
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    XCTAssertFalse([encDb isLocked], @"database was in locked state after creation");
    [TSEncryptedDatabase databaseLock];
    XCTAssertTrue([encDb isLocked], @"database was in unlocked state after getting locked");
}


- (void)testDatabaseUnlock
{
    NSError *error = nil;
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    
    encDb = [TSEncryptedDatabase databaseUnlockWithPassword:dbPw error:&error];
    XCTAssertNotNil(encDb, @"valid password did not unlock the database");
    XCTAssertNil(error, @"valid password returned an error");
    
    XCTAssertNotNil([encDb getPersonalPrekeys], @"could not retrieve user keys");
    XCTAssertNotNil([encDb getIdentityKey], @"could not retrieve user keys");
}


- (void)testDatabaseUnlockWithWrongPassword
{
    NSError *error = nil;
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseUnlockWithPassword:@"wrongpw" error:&error];
    XCTAssertNil(encDb, @"wrong password unlocked the database");
    // TODO: Look at the actual error code
    XCTAssertNotNil(error, @"wrong password did not return an error");
}


- (void)testDatabaseUnlockWithDeletedKeychain
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:encryptedMasterSecretKeyStorageId];
    XCTAssertThrows([TSEncryptedDatabase databaseUnlockWithPassword:dbPw error:nil], @"database was unlocked with deleted keychain");
}


- (void)testDatabaseUnlockWithCorruptedKeychain
{
    [TSEncryptedDatabase databaseCreateWithPassword:dbPw error:nil];
    [TSEncryptedDatabase databaseLock];
    
    //TODO Fix this
    //NSData *encryptedDbMasterKey = [Cryptography AES256Encryption:[Cryptography generateRandomBytes:36] withPassword:dbPw];
    //[KeychainWrapper createKeychainValue:[encryptedDbMasterKey base64EncodedString] forIdentifier:encryptedMasterSecretKeyStorageId];
    //XCTAssertThrows([TSEncryptedDatabase databaseUnlockWithPassword:dbPw error:nil], @"database was unlocked with corrupted keychain");
}


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
