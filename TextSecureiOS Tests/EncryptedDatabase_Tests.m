//
//  TextSecureiOS_Tests.m
//  TextSecureiOS Tests
//
//  Created by Alban Diquet on 11/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EncryptedDatabase.h"


static NSString *dbPw = @"1234test";

@interface EncryptedDatabase_Tests : XCTestCase

@end

@implementation EncryptedDatabase_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDatabaseCreate
{
    EncryptedDatabase *encDb = [EncryptedDatabase databaseCreateWithPassword:dbPw];
    XCTAssertNotNil(encDb, @"database creation failed");
}


- (void)testDatabaseUnlock

{
    NSError *error = nil;
    // Wrong password
    EncryptedDatabase *encDb = [EncryptedDatabase databaseUnlockWithPassword:@"wrongpw" error:&error];
    XCTAssertNil(encDb, @"wrong password unlocked the database");
    // TODO: Check the error itself
    XCTAssertNotNil(error, @"wrong password did not return an error");
    
    // Good password
    encDb = [EncryptedDatabase databaseUnlockWithPassword:dbPw error:&error];
    XCTAssertNotNil(encDb, @"valid password did not unlock the database");
    XCTAssertNil(error, @"valid password returned an error");
}

@end
