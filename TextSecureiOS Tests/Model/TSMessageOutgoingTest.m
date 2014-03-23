//
//  TSMessageOutgoingTest.m
//  TextSecureiOS
//
//  Created by Daniel Cestari on 3/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TSMessageOutgoing.h"
#import "TSGroup.h"

@interface TSMessageOutgoingTest : XCTestCase

@end

@implementation TSMessageOutgoingTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testInitMessageWithContent
{
    NSString *content = @"Hello";
    NSString *recipientId = @"+1234567890";
    NSDate *date = [NSDate date];
    NSArray *attachments = @[];
    TSGroup *group = nil;
    TSMessageOutgoingState state = TSMessageStatePendingSend;

    TSMessageOutgoing *message = [[TSMessageOutgoing alloc] initMessageWithContent:content
                                                                             recipient:recipientId
                                                                                  date:date
                                                                          attachements:attachments
                                                                                 group:group
                                                                                 state:state];

    XCTAssertNotNil(message);
    XCTAssertEqual(message.content, content);
    XCTAssertEqual(message.recipientId, recipientId);
    XCTAssertEqual(message.timestamp, date);
    XCTAssertEqual(message.attachments, attachments);
    XCTAssertEqual(message.group, group);
    XCTAssertEqual(message.state, state);
}

@end
