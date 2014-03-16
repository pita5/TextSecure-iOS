//
//  TSMessageIncomingTest.m
//  TextSecureiOS
//
//  Created by Daniel Cestari on 3/14/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSMessageIncoming.h"

@interface TSMessageIncomingTest : XCTestCase

@end

@implementation TSMessageIncomingTest

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

- (void)testInitMessageWithContent
{
    NSString *content = @"Hello";
    NSString *senderId = @"+1234567890";
    NSDate *date = [NSDate date];
    NSArray *attachments = @[];
    TSGroup *group = nil;
    TSMessageIncomingState state = TSMessageStateReceived;

    TSMessageIncoming *message = [[TSMessageIncoming alloc] initWithMessageWithContent:content
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
    __block TSMessageIncoming *message = [[TSMessageIncoming alloc] initWithMessageWithContent:nil
                                                                                sender:nil
                                                                                  date:nil
                                                                          attachements:nil
                                                                                 group:nil
                                                                                 state:TSMessageStateReceived];

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
