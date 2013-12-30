//
//  TSEncryptedDatabase2Tests.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSEncryptedDatabase2.h"
#import "TSStorageMasterKey.h"
#import "FilePath.h"

@interface TSEncryptedDatabase2Tests : XCTestCase

@end


static NSString *masterPw = @"1234test";
static NSString *dbFileName = @"test.db";
static NSString *dbPreference = @"WasTestDbCreated";


@implementation TSEncryptedDatabase2Tests

- (void)setUp
{
    [super setUp];
    
    // Create a storage master key
    [TSStorageMasterKey eraseStorageMasterKey];
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw];
    
    [TSEncryptedDatabase2 databaseEraseAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}



- (void)testDatabaseCreate
{
    NSError *error = nil;
    TSEncryptedDatabase2 *encDb = [TSEncryptedDatabase2  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    
    XCTAssertNotNil(encDb, @"database creation returned nil");
    XCTAssertNil(error, @"database creation returned an error");
}


- (void)testDatabaseCreateWithPreviousDatabaseRemnants
{
    NSError *error = nil;
    [TSEncryptedDatabase2  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:@"" error:nil];
    
    TSEncryptedDatabase2 *encDb = [TSEncryptedDatabase2  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    // TODO: check for the specific error code
    XCTAssertNil(error, @"database creation returned an error");
    XCTAssertNotNil(encDb, @"database creation failed");
}


- (void)testDatabaseCreateWithoutMasterStorageKey
{
    [TSStorageMasterKey eraseStorageMasterKey];
    NSError *error = nil;
    TSEncryptedDatabase2 *encDb = [TSEncryptedDatabase2  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    
    // TODO: check for the specific error code
    XCTAssertNotNil(error, @"database creation succeeded with no master key");
    XCTAssertNil(encDb, @"database creation succeeded with no master key");
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw];
}


- (void)testDatabaseCreateAndOverwrite
{
    NSError *error = nil;
    [TSEncryptedDatabase2  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    
    TSEncryptedDatabase2 *encDb = [TSEncryptedDatabase2  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    // TODO: check for the specific error code
    XCTAssertNotNil(error, @"database overwrite did not return an error");
    XCTAssertNil(encDb, @"database overwrite succeeded");
}


- (void)testDatabaseDecrypt
{
    [TSEncryptedDatabase2  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:nil];
    
    NSError *error = nil;
    TSEncryptedDatabase2 *encDb = [TSEncryptedDatabase2 databaseOpenAndDecryptAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] error:&error];
    
    XCTAssertNotNil(encDb, @"database decryption returned nil");
    XCTAssertNil(error, @"database decryption returned an error");
}

// TODO: add more tests once errors have been defined


@end
