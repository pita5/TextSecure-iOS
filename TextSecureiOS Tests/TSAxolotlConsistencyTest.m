//
//  TSAxolotlConsistencyTest.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 26/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//



/**
 ......................................................................
 .   o   \ o /  _ o        __|    \ /     |__         o _  \ o /   o   .
 .  /|\    |     /\   __\o   \o    |    o/     o/__   /\     |    /|\  .
 .  / \   / \   | \  /) |    ( \  /o\  / )    |   (\  / |   / \   / \  .
 .       .......................................................       .
 . \ o / .                                                     . \ o / .
 .   |   .                                                     .   |   .
 .  / \  .                                                     .  / \  .
 .       .                                                     .       .
 .  _ o  .                                                     .  _ o  .
 .   /\  .                                                     .   /\  .
 .  | \  .                                                     .  | \  .
 .       .                                                     .       .
 .       .                                                     .       .
 .  __\o .                                                     .  __\o .
 . /) |  .                                                     . /) |  .
 .       .                                                     .       .
 . __|   .                                                     . __|   .
 .   \o  .                                                     .    \o .
 .   ( \ .                                                     .   ( \ .
 .       .                                                     .       .
 .  \ /  .                                                     .  \ /  .
 .   |   .                 !!!    WARNING    !!!               .   |   .
 .  /o\  .      The following tests do not prove that the      .  /o\  .
 .       .      ratchet is properly implemented but just       .       .
 .   |__ .      that the implementation is consistent.         .   |__ .
 . o/    .                                                     . o/    .
 ./ )    .                                                     ./ )    .
 .       .                                                     .       .
 .       .                                                     .       .
 . o/__  .                                                     . o/__  .
 .  | (\ .                                                     . |  (\ .
 .       .                                                     .       .
 .  o _  .                                                     .  o _  .
 .  /\   .                                                     .  /\   .
 .  / |  .                                                     .  / |  .
 .       .                                                     .       .
 . \ o / .                                                     . \ o / .
 .   |   .                                                     .   |   .
 .  / \  .                                                     .  / \  .
 .       .......................................................       .
 .   o   \ o /  _ o        __|    \ /     |__         o _  \ o /   o   .
 .  /|\    |     /\   __\o   \o    |    o/     o/__   /\     |    /|\  .
 .  / \   / \   | \  /) |    ( \  /o\  / )    |   (\  / |   / \   / \  .
 dc.....................................................................
 */




#import <XCTest/XCTest.h>

@interface TSAxolotlConsistencyTest : XCTestCase

@end

@implementation TSAxolotlConsistencyTest

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

- (void)testEncryptionDecryption
{
    NSString *senderID = @"+10000000";
    NSString *receiverID = @"+41000000";
    /**
     *  Session for encryption
     */
    
    
    
    /**
     *  Session for decryption
     */
    
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
