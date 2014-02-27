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
#import "TSThread.h"
#import "TSContact.h"
#import "TSECKeyPair.h"
#import "TSMessage.h"

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
@property (nonatomic,strong) TSThread* thread;
@property (nonatomic,strong) TSMessage* message;

@end

@implementation TSMessagesDatabaseTests

- (void)setUp
{
    [super setUp];
    
    self.thread = [TSThread threadWithContacts:@[[[TSContact alloc] initWithRegisteredID:@"678910"]]];
    
    self.message = [TSMessage messageWithContent:@"hey" sender:@"12345" recipient:@"678910" date:[NSDate date]];
    // Remove any existing DB
    [TSMessagesDatabase databaseErase];
    
    [TSStorageMasterKey eraseStorageMasterKey];
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    
    NSError *error;
    
    // tests datbase creation
    
    XCTAssertTrue([TSMessagesDatabase databaseCreateWithError:&error], @"message db creation failed");
    XCTAssertNil(error, @"message db creation returned an error");
    
    __block BOOL done = NO;
    
    NSArray *threadsFromDb = [TSMessagesDatabase threads];
    NSArray *messages = [TSMessagesDatabase messagesOnThread:self.thread];
    
    
    
    
            [TSMessagesDatabase getMessagesOnThread:self.thread withCompletion:^(NSArray* messages) {
                XCTAssertTrue([threadsFromDb count]==0, @"there are threads in an empty db");
                XCTAssertTrue([messages count]==0, @"there are threads in an empty db");
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [TSMessagesDatabase storeMessage:self.message fromThread:self.thread withCompletionBlock:^(BOOL success) {
                        done = YES;
                    }];
                    
                });
            }];
        });
        
    }];
    
    while(!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [TSStorageMasterKey eraseStorageMasterKey];
}

-(void) testStoreMessage {
    __block BOOL done = NO;
    [TSMessagesDatabase getMessagesOnThread:self.thread withCompletion:^(NSArray* messages) {
        XCTAssertTrue([messages count]==1, @"database should just have one message in it, instead has %d",[messages count]);
        XCTAssertTrue([[[messages objectAtIndex:0] content] isEqualToString:self.message.content], @"message bodies not equal");
        done = YES;
    }];
    while(!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testStoreThreadCreation {
    __block BOOL done = NO;
    [TSMessagesDatabase getThreadsWithCompletion:^(NSArray *threadsFromDb) {
        XCTAssertTrue([threadsFromDb count]==1, @"database should just have one thread in it, instead has %d",[threadsFromDb count]);
        
        XCTAssertTrue([[[threadsFromDb objectAtIndex:0] threadID] isEqualToString:self.thread.threadID], @"thread id %@ of thread retreived and my thread %@ not equal", [[threadsFromDb objectAtIndex:0] threadID], self.thread.threadID);
        done = YES;
    }];
    
    while(!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testAPSDataStorage {
    NSData *data = [Cryptography generateRandomBytes:100];
    __block BOOL done = NO;
    [TSMessagesDatabase setAPSDataField:@{@"valueField":data,@"threadID":self.thread.threadID, @"nameField": @"cks"} withCompletion:^(BOOL success) {
        XCTAssertTrue(success, @"The DB field coudn't be set");
        
        [TSMessagesDatabase getAPSDataField:@"cks" onThread:self.thread withCompletion:^(NSData *apsdata) {
            XCTAssertTrue([data isEqualToData:apsdata], @"data field retreived  %@ not equal to the randomly generated data and set into the database %@", apsdata,data);
            done = YES;
        }];
    }];
    
}

-(void) testRKStorage {
    NSData* RK = [Cryptography generateRandomBytes:20];
    __block BOOL done = NO;
    [TSMessagesDatabase setRK:RK onThread:self.thread withCompletionBlock:^(BOOL success) {
        [TSMessagesDatabase getRK:self.thread withCompletionBlock:^(NSData *data) {
            XCTAssertTrue([RK isEqualToData:data], @"Storing and retreiving RK doesn't give the right value.");
            done = YES;
        }];
    }];
    while(!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testCKStorage {
    __block BOOL done = NO;
    NSData* CKSending = [Cryptography generateRandomBytes:20];
    NSData* CKReceiving = [Cryptography generateRandomBytes:20];
    
    [TSMessagesDatabase setCK:CKReceiving onThread:self.thread onChain:TSReceivingChain withCompletionBlock:^(BOOL success) {
        [TSMessagesDatabase setCK:CKSending onThread:self.thread onChain:TSSendingChain withCompletionBlock:^(BOOL success) {
            [TSMessagesDatabase getCK:self.thread onChain:TSSendingChain withCompletionBlock:^(NSData *sendingChainData) {
                XCTAssertTrue([CKSending isEqualToData:sendingChainData], @"CK sending on thread %@ getter not equal to setter %@", sendingChainData,CKSending);
                [TSMessagesDatabase getCK:self.thread onChain:TSReceivingChain withCompletionBlock:^(NSData *receivingChainData) {
                    XCTAssertTrue([CKReceiving isEqualToData:receivingChainData], @"CK receiving on thread %@ getter not equal to setter %@",receivingChainData, CKReceiving);
                    done = YES;
                }];
            }];
        }];
    }];
    
    while(!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testEphemeralStorageReceiving {
    __block BOOL done = NO;
    
    NSData* publicReceiving = [Cryptography generateRandomBytes:32];
    [TSMessagesDatabase setEphemeralOfReceivingChain:publicReceiving onThread:self.thread withCompletionBlock:^(BOOL success) {
        if (success) {
            [TSMessagesDatabase getEphemeralOfReceivingChain:self.thread withCompletionBlock:^(NSData *data) {
                XCTAssertTrue([publicReceiving isEqualToData: data], @"public receiving ephemeral on thread %@ getter not equal to setter %@",data,publicReceiving);
                done = YES;
            }];
        }
    }];
    while(!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testEphemeralStorageSending {
    __block BOOL done = NO;
    
    TSECKeyPair *pairSending = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
    [TSMessagesDatabase setEphemeralOfSendingChain:pairSending onThread:self.thread withCompletionBlock:^(BOOL success) {
        if (success) {
            [TSMessagesDatabase getEphemeralOfSendingChain:self.thread]) {
                XCTAssertTrue([[keyPair getPublicKey] isEqualToData:[pairSending getPublicKey]], @"public keys of ephemerals on sending chain not equal");
                XCTAssertTrue([[keyPair getPrivateKey] isEqualToData:[pairSending getPrivateKey]], @"private keys of ephemerals on sending chain not equal");
                done = YES;
            }];
        }
        
    }];
    
    while(!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void) testEphemeralStorageN {
    __block BOOL done = NO;
    
    [TSMessagesDatabase getN:self.thread onChain:TSSendingChain withCompletionBlock:^(NSNumber *number) {
        XCTAssert([number isEqualToNumber:[NSNumber numberWithInt:0]], @"N doesn't default to 0 on sending chain");
        
        [TSMessagesDatabase getN:self.thread onChain:TSReceivingChain withCompletionBlock:^(NSNumber *number) {
            XCTAssert([number isEqualToNumber:[NSNumber numberWithInt:0]], @"N doesn't default to 0 on receiving chain");
            
            
            [TSMessagesDatabase getPNs:self.thread withCompletionBlock:^(NSNumber *number) {
                XCTAssert([number isEqualToNumber:[NSNumber numberWithInt:0] ],@"PNs doesn't default to 0 ");
                
                
                NSNumber* NSending = [NSNumber numberWithInt:2];
                NSNumber* NReceiving = [NSNumber numberWithInt:3];
                NSNumber* PNSending = [NSNumber numberWithInt:5];
                
                
                [TSMessagesDatabase setPNs:PNSending onThread:self.thread withCompletionBlock:^(BOOL success) {
                    [TSMessagesDatabase getPNs:self.thread withCompletionBlock:^(NSNumber *number) {
                        XCTAssert([PNSending isEqualToNumber:number], @"PNs are not set correctly");
                        
                        [TSMessagesDatabase setN:NSending onThread:self.thread onChain:TSSendingChain withCompletionBlock:^(BOOL success) {
                            [TSMessagesDatabase setN:NReceiving onThread:self.thread onChain:TSReceivingChain withCompletionBlock:^(BOOL success) {
                                if (success) {
                                    [TSMessagesDatabase getNPlusPlus:self.thread onChain:TSSendingChain withCompletionBlock:^(NSNumber *number) {
                                        XCTAssert([number isEqualToNumber:NSending], @"Ns are not set correctly on the sending chain");
                                        [TSMessagesDatabase getN:self.thread onChain:TSSendingChain withCompletionBlock:^(NSNumber *number) {
                                            XCTAssert([number isEqualToNumber:[NSNumber numberWithInt:3]], @"The N incrementation on the sending chain return wrong results");
                                            
                                            [TSMessagesDatabase getNPlusPlus:self.thread onChain:TSReceivingChain withCompletionBlock:^(NSNumber *number) {
                                                XCTAssert([number isEqualToNumber:NReceiving], @"Ns are not set correctly on the receiving chain"); 
                                                [TSMessagesDatabase getN:self.thread onChain:TSReceivingChain withCompletionBlock:^(NSNumber *number) {
                                                    XCTAssert([number isEqualToNumber:[NSNumber numberWithInt:4]], @"The N incrementation on the receiving chain return wrong results");
                                                    
                                                    done = YES;
                                                }];
                                                
                                                
                                            }];
                                            
                                        }];
                                        
                                    }];
                                }
                            }];
                        }];
                    }];
                }];
            }];
            
        }];
    }];
    
    while(!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

@end
