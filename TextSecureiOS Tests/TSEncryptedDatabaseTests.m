//
//  TSEncryptedDatabase2Tests.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 12/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSStorageError.h"
#import "TSDatabaseManager.h"
#import "TSStorageMasterKey.h"
#import "FilePath.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@interface TSEncryptedDatabaseTests : XCTestCase

@end


static NSString *masterPw = @"1234test";
static NSString *dbFileName = @"test.db";
static NSString *dbPreference = @"WasTestDbCreated";


@implementation TSEncryptedDatabaseTests

- (void)setUp
{
    [super setUp];
    
    // Create a storage master key
    [TSStorageMasterKey eraseStorageMasterKey];
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    
    [TSDatabaseManager databaseEraseAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}



- (void)testDatabaseCreate
{
    NSError *error = nil;
    TSDatabaseManager *encDb = [TSDatabaseManager  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    
    XCTAssertNotNil(encDb, @"database creation returned nil");
    XCTAssertNil(error, @"database creation returned an error");
}


- (void)testDatabaseCreateWithPreviousDatabaseRemnants
{
    NSError *error = nil;
    [TSDatabaseManager  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:@"" error:nil];
    
    TSDatabaseManager *encDb = [TSDatabaseManager  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];

    XCTAssertNil(error, @"database creation returned an error");
    XCTAssertNotNil(encDb, @"database creation failed");
}


- (void)testDatabaseCreateWithoutMasterStorageKey
{
    [TSStorageMasterKey eraseStorageMasterKey];
    NSError *error = nil;
    TSDatabaseManager *encDb = [TSDatabaseManager  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    
    XCTAssertNotNil(error, @"database creation succeeded with no master key");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"database creation succeeded with no master key returned an unexpected error");
    XCTAssertEqual([error code], TSStorageErrorStorageKeyNotCreated, @"database creation succeeded with no master key returned an unexpected error");
    XCTAssertNil(encDb, @"database creation succeeded with no master key");
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
}


- (void)testDatabaseCreateAndOverwrite
{
    NSError *error = nil;
    [TSDatabaseManager  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    
    TSDatabaseManager *encDb = [TSDatabaseManager  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:&error];
    
    XCTAssertNotNil(error, @"database overwrite did not return an error");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"database overwrite returned an unexpected error");
    XCTAssertEqual([error code], TSStorageErrorDatabaseAlreadyCreated, @"database overwrite returned an unexpected error");
    XCTAssertNil(encDb, @"database overwrite succeeded");
}


- (void)testDatabaseDecrypt
{
    [TSDatabaseManager  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:nil];
    
    NSError *error = nil;
    TSDatabaseManager *encDb = [TSDatabaseManager databaseOpenAndDecryptAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] error:&error];
    
    XCTAssertNotNil(encDb, @"database decryption returned nil");
    XCTAssertNil(error, @"database decryption returned an error");
}

- (void)testDatabaseDecryptWithCorruptedStorageKey
{
    NSError *error = nil;
    TSDatabaseManager *encDb = [TSDatabaseManager  databaseCreateAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] updateBoolPreference:dbPreference error:nil];
    
    // Write something to the DB
    [encDb.dbQueue inDatabase: ^(FMDatabase *db) {
        [db executeUpdate:@"CREATE TABLE user_identity_key (serialized_keypair BLOB)"];
    }];
    
    // Replace the storage key but use the same password
    [TSStorageMasterKey eraseStorageMasterKey];
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:&error];

    encDb = [TSDatabaseManager databaseOpenAndDecryptAtFilePath:[FilePath pathInDocumentsDirectory:dbFileName] error:&error];
    
    XCTAssertNotNil(error, @"database decryption with invalid storage key did not return an error");
    XCTAssertTrue([[error domain] isEqualToString:TSStorageErrorDomain], @"database decryption with invalid storage key returned an unexpected error");
    XCTAssertEqual([error code], TSStorageErrorStorageKeyCorrupted, @"database decryption with invalid storage key returned an unexpected error");
    XCTAssertNil(encDb, @"database decryption with invalid storage key succeeded");
}



@end
