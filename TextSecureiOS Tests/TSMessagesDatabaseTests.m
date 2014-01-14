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
#import "TSParticipants.h"
#import "TSContact.h"
#import "TSECKeyPair.h"
static NSString *masterPw = @"1234test";


@interface TSMessagesDatabaseTests : XCTestCase
@property (nonatomic,strong) TSThread* thread;
@end

@implementation TSMessagesDatabaseTests

- (void)setUp
{
    [super setUp];
    self.thread = [TSThread threadWithParticipants:[[TSParticipants alloc] initWithTSContactsArray:@[[[TSContact alloc] initWithRegisteredID:@"12345"],[[TSContact alloc] initWithRegisteredID:@"678910"]]]];
    // Remove any existing DB
    [TSMessagesDatabase databaseErase];
    
    
    [TSStorageMasterKey eraseStorageMasterKey];
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:nil];
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [TSStorageMasterKey eraseStorageMasterKey];
}



- (void)testDatabaseCreate
{
    NSError *error;
    
    XCTAssertTrue([TSMessagesDatabase databaseCreateWithError:&error], @"message db creation failed");
    XCTAssertNil(error, @"message db creation returned an error");
    
}

//TODO : get / set content
- (void) testAxolotlPersistantStorage {
  /*
   +(NSData*) getRK:(TSThread*)thread;
   +(void) setRK:(NSData*)key onThread:(TSThread*)thread;
   //CKs, CKr     : 32-byte chain keys (used for forward-secrecy updating)
   +(NSData*) getCK:(TSThread*)thread onChain:(TSChainType)chain;
   +(void) setCK:(NSData*)key onThread:(TSThread*)thread onChain:(TSChainType)chain;
   //DHIs, DHIr   : DH or ECDH Identity keys
   +(NSData*) getEphemeralOfReceivingChain:(TSThread*)thread;
   +(void) setEphemeralOfReceivingChain:(NSData*)key onThread:(TSThread*)thread;
   +(TSECKeyPair*) getEphemeralOfSendingChain:(TSThread*)thread;
   
   +(void) setEphemeralOfSendingChain:(TSECKeyPair*)key onThread:(TSThread*)thread;
   //Ns, Nr       : Message numbers (reset to 0 with each new ratchet)
   +(NSNumber*) getN:(TSThread*)thread onChain:(TSChainType)chain;
   +(void) setN:(NSNumber*)num onThread:(TSThread*)thread onChain:(TSChainType)chain;
   // sets N to N+1 returns value of N prior to setting,  Message numbers (reset to 0 with each new ratchet)
   +(NSNumber*) getNPlusPlus:(TSThread*)thread onChain:(TSChainType)chain;
   
   //PNs          : Previous message numbers (# of msgs sent under prev ratchet) only relevant for sending chain
   +(NSNumber*)getPNs:(TSThread*)thread;
   +(void)setPNs:(NSNumber*)num onThread:(TSThread*)thread;
   */
  
  
  NSLog(@"threadid %@",self.thread.threadID);
  NSData* RK = [Cryptography generateRandomBytes:20];
  NSData* CKSending = [Cryptography generateRandomBytes:20];
  NSData* CKReceiving = [Cryptography generateRandomBytes:20];
  NSData* publicReceiving = [Cryptography generateRandomBytes:32];
  TSECKeyPair *pairSending = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  NSNumber* NSending = [NSNumber numberWithInt:2];
  NSNumber* NReceiving = [NSNumber numberWithInt:3];
  NSNumber* PNSending = [NSNumber numberWithInt:5];
  
  [TSMessagesDatabase setRK:RK onThread:self.thread];
  XCTAssertTrue([RK isEqualToData:[TSMessagesDatabase getRK:self.thread]], @"RK on thread getter not equal to setter");
  
  
  
  
}


@end
