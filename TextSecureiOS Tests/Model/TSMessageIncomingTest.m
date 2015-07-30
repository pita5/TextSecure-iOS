//
//  TSMessageIncomingTest.m
//  TextSecureiOS
//
//  Created by Daniel Cestari on 3/14/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSMessageIncoming.h"
#import "TSKeyManager.h"
#import "TSMessagesDatabase.h"
#import "TSStorageMasterKey.h"

@interface TSMessageIncomingTest : XCTestCase

@end

@implementation TSMessageIncomingTest

- (void)setUp
{
    
    static NSString *masterPw = @"1234test";
    static NSString *dbFileName = @"test.db";
    static NSString *dbPreference = @"WasTestDbCreated";
    
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    [TSKeyManager storeUsernameToken:@"56789"];
    
    // Remove any existing DB
    [TSMessagesDatabase databaseErase];
    
    
    [TSStorageMasterKey eraseStorageMasterKey];
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    
    NSError *error;
    
    // tests datbase creation
    
    XCTAssertTrue([TSMessagesDatabase databaseCreateWithError:&error], @"message db creation failed");
    XCTAssertNil(error, @"message db creation returned an error");
    
    // tests is empty
    NSArray* threadsFromDb = [TSMessagesDatabase conversations];
    XCTAssertTrue([threadsFromDb count]==0, @"there are threads in an empty db");
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInitMessageWithContent
{
    NSString *content = @"Hello";
    NSString *senderId = @"+1234567890";
    NSDate *date = [NSDate date];
    NSArray *attachments = @[];
    TSGroup *group = nil;
    TSMessageIncomingState state = TSMessageStateReceived;

    TSMessageIncoming *message = [[TSMessageIncoming alloc] initMessageWithContent:content
                                                                             sender:senderId
                                                                                  date:date
                                                                          attachements:attachments
                                                                                 group:group
                                                                                 state:state];

    XCTAssertNotNil(message);
    XCTAssertEqual(message.content, content);
    XCTAssertEqual(message.senderId, senderId);
    XCTAssertEqual(message.timestamp, date);
    XCTAssertEqual(message.attachments, attachments);
    XCTAssertEqual(message.group, group);
    XCTAssertEqual(message.state, state);
}

- (void)testSetStateWithCompletion
{
    NSString *content = @"Hello";
    NSString *senderId = @"+1234567890";
    NSDate *date = [NSDate date];
    NSArray *attachments = @[];
    TSGroup *group = nil;
    TSMessageIncomingState state = TSMessageStateReceived;
    
    TSMessageIncoming *message = [[TSMessageIncoming alloc] initMessageWithContent:content
                                                                            sender:senderId
                                                                              date:date
                                                                      attachements:attachments
                                                                             group:group
                                                                             state:state];
    XCTAssertEqual(message.state, TSMessageStateReceived);

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [message setState:TSMessageStateRead withCompletion:^(BOOL success) {
        if (success) {
            XCTAssertEqual(message.state, TSMessageStateRead);
        } else {
            XCTFail(@"method reported failure");
        }

        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}


@end
