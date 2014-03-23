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
#import "TSSession.h"

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

- (void) testStoreMessage {
    NSArray *messages = [TSMessagesDatabase messagesWithContact:self.contact];
    XCTAssertTrue([messages count]==1, @"database should just have one message in it, instead has %lu",(unsigned long)[messages count]);
    XCTAssertTrue([[[messages objectAtIndex:0] content] isEqualToString:self.message.content], @"message bodies not equal");
}

- (void)testStoreSession{
    XCTAssertTrue([[TSMessagesDatabase sessionsForContact:self.contact] count] == 0, @"We had sessions before test started!");
    
    TSSession *session = [[TSSession alloc] initWithContact:self.contact deviceId:1];
    
    session.rootKey = [Cryptography generateRandomBytes:10];
    session.senderChainKey = [[TSChainKey alloc]initWithChainKeyWithKey:[Cryptography generateRandomBytes:10] index:1];
    
    session.senderEphemeral = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
    
    NSData *chainData = [Cryptography generateRandomBytes:10];
    NSData *chainKey = [Cryptography generateRandomBytes:10];
    
    [session addReceiverChain:chainData chainKey:[[TSChainKey alloc] initWithChainKeyWithKey:chainKey index:1]];
    
    [TSMessagesDatabase storeSession:session];
    
    TSSession *retreivedSession = [TSMessagesDatabase sessionForRegisteredId:self.contact.registeredID deviceId:1];
    
    XCTAssertTrue([retreivedSession.rootKey isEqualToData:session.rootKey], @"Rootkeys don't match");
    XCTAssertTrue([retreivedSession.senderChainKey.key isEqualToData:session.senderChainKey.key], @"SenderKeyChain keys don't match");
    XCTAssertTrue([retreivedSession.senderEphemeral.publicKey isEqualToData:session.senderEphemeral.publicKey], @"SenderEphemeral keys don't match");
    XCTAssertTrue([[retreivedSession receiverChainKey:chainData].key isEqualToData:chainKey], @"Receiver chain keys don't match");
    
    // The basic properties seem to be saved properly, now let's test 5 with 5 receiving chains and a change of some properties.
    
    NSMutableArray *chainKeys = [NSMutableArray array];
    NSMutableArray *ephemerals = [NSMutableArray array];
    for (int i = 5; i > 0; i--) {
        TSChainKey *chainKey = [[TSChainKey alloc]initWithChainKeyWithKey:[Cryptography generateRandomBytes:30] index:1];
        NSData *randomData = [Cryptography generateRandomBytes:32];
        [retreivedSession addReceiverChain:randomData chainKey:chainKey];
        [chainKeys addObject:chainKey];
        [ephemerals addObject:randomData];
    }
    
    [TSMessagesDatabase storeSession:retreivedSession];
    
    TSSession *retreivedSession2 = [TSMessagesDatabase sessionForRegisteredId:self.contact.registeredID deviceId:1];
    
    for (int i = 4; i >= 0; i --) {
        XCTAssert([[retreivedSession2 receiverChainKey:[ephemerals objectAtIndex:i]].key isEqualToData: ((TSChainKey*)[chainKeys objectAtIndex:i]).key], @"ChainKey not updated!");
    }
}


@end
