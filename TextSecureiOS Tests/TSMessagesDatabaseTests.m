//
//  TSMessagesDatabase.m
//  TSMessagesDatabase Tests
//
//  Created by Alban Diquet on 11/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSMessagesDatabase.h"
#import "TSStorageError.h"
#import "Cryptography.h"
#import "NSData+Base64.h"
#import "TSStorageMasterKey.h"
#import "TSContact.h"
#import "TSECKeyPair.h"
#import "TSMessage.h"
#import "TSKeyManager.h"
#import "Constants.h"

static NSString *masterPw = @"1234test";

@interface TSECKeyPair (Test)
-(NSData*) getPrivateKey;
@end


@implementation TSECKeyPair (Test)
-(NSData*) getPrivateKey {
    return [NSData dataWithBytes:self->privateKey length:32];
}
@end

@interface TSMessagesDatabaseTests : XCTestCase
@property (nonatomic) TSContact *contact;
@property (nonatomic) TSMessage* message;

@end

@implementation TSMessagesDatabaseTests

- (void)setUp
{
    [super setUp];
    
    [TSKeyManager storeUsernameToken:@"56789"];
    
    self.contact = [[TSContact alloc] initWithRegisteredID:@"12345" relay:nil];
    
    self.message = [[TSMessage alloc] initWithSenderId:[TSKeyManager getUsernameToken] recipientId:self.contact.registeredID date:[NSDate date] content:@"Hello World" attachements:nil groupId:nil];
    
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
    NSArray *messages = [TSMessagesDatabase messagesWithContact:self.contact];
    XCTAssertTrue([threadsFromDb count]==0, @"there are threads in an empty db");
    XCTAssertTrue([messages count]==0, @"there are threads in an empty db");
    
    [TSMessagesDatabase storeMessage:self.message];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [TSStorageMasterKey eraseStorageMasterKey];
}

-(void) testStoreMessage {
    NSArray *messages = [TSMessagesDatabase messagesWithContact:self.contact];
    XCTAssertTrue([messages count]==1, @"database should just have one message in it, instead has %lu",(unsigned long)[messages count]);
    XCTAssertTrue([[[messages objectAtIndex:0] content] isEqualToString:self.message.content], @"message bodies not equal");
    
}


@end
