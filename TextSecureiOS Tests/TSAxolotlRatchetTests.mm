//
//  TSAxolotlProtocolTests.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TSAxolotlRatchet.hh"
#import "Cryptography.h"
#import "TSECKeyPair.h"
#import "TSHKDF.h"
#import "TSWhisperMessageKeys.h"
@interface TSAxolotlRatchetTests : XCTestCase
@property (nonatomic,strong) TSAxolotlRatchet *ratchet;
@end

@interface NSData (Split)
-(NSData*) firstHalfsOfData;
-(NSData*) secondHalfOfData;

@end

@implementation NSData (Split)

-(NSData*) firstHalfsOfData {
  int size = [self length]/2;
  return [self subdataWithRange:NSMakeRange(0, size)];
}
-(NSData*) secondHalfOfData {
  int size = [self length]/2;
  return [self subdataWithRange:NSMakeRange(size,size)];
}

@end
// To avoid + h files
@interface TSAxolotlRatchet (Test)

-(NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey;
-(NSData*)masterKeyBob:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey;
-(TSWhisperMessageKeys*) deriveTSWhisperMessageKeysFromMessageKey:(NSData*)nextMessageKey_MK;
#pragma mark private test methods
+(NSData*)nextMessageAndChainKeyTest:(NSData*)CK;
+(NSData*)newRootKeyAndChainKeyWithTheirPublicEphemeral:(NSData*)theirPublicEphemeral fromMyNewEphemeral:(TSECKeyPair*)newEphemeral withExistingRK:(NSData*)existingRK;

@end


@implementation TSAxolotlRatchet (Test)

+(NSData*)nextMessageAndChainKeyFromChainKey:(NSData*)CK {
  /* Chain Key Derivation */
  int hmacKeyMK = 0x01;
  int hmacKeyCK = 0x02;
  NSData* nextMK = [Cryptography computeHMAC:CK withHMACKey:[NSData dataWithBytes:&hmacKeyMK length:sizeof(hmacKeyMK)]];

  NSData* nextCK = [Cryptography computeHMAC:CK  withHMACKey:[NSData dataWithBytes:&hmacKeyCK length:sizeof(hmacKeyCK)]];
  NSMutableData *mkCK = [NSMutableData data];
  [mkCK appendData:nextMK];
  [mkCK appendData:nextCK];
  return mkCK;
}

+(NSData*)newRootKeyAndChainKeyWithTheirPublicEphemeral:(NSData*)theirPublicEphemeral fromMyNewEphemeral:(TSECKeyPair*)newEphemeral withExistingRK:(NSData *)existingRK {
  NSData* inputKeyMaterial = [newEphemeral generateSharedSecretFromPublicKey:theirPublicEphemeral];
  NSData* newRkCK  = [TSHKDF deriveKeyFromMaterial:inputKeyMaterial outputLength:64 info:[@"WhisperRatchet" dataUsingEncoding:NSASCIIStringEncoding] salt:existingRK];
  return newRkCK;
}


@end


@implementation TSAxolotlRatchetTests

- (void)setUp
{
    self.ratchet = [[TSAxolotlRatchet alloc] init];
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

-(void) testMasterKeyGeneration {
  TSECKeyPair *aliceIdentityKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *aliceEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *bobIdentityKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *bobEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  NSData* aliceMasterKey = [self.ratchet masterKeyAlice:aliceIdentityKey ourEphemeral:aliceEphemeralKey   theirIdentityPublicKey:[bobIdentityKey getPublicKey] theirEphemeralPublicKey:[bobEphemeralKey getPublicKey]];
  
  
  NSData* bobMasterKey = [self.ratchet masterKeyBob:bobIdentityKey ourEphemeral:bobEphemeralKey theirIdentityPublicKey:[aliceIdentityKey getPublicKey] theirEphemeralPublicKey:[aliceEphemeralKey getPublicKey]];
  XCTAssertTrue([aliceMasterKey isEqualToData:bobMasterKey], @"alice and bob master keys not equal");
}

-(void) testRatchet {
  TSECKeyPair *aliceIdentityKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *aliceEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *bobIdentityKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *bobEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  // ratchet alice
  NSData* aliceMasterKey = [self.ratchet masterKeyAlice:aliceIdentityKey ourEphemeral:aliceEphemeralKey   theirIdentityPublicKey:[bobIdentityKey getPublicKey] theirEphemeralPublicKey:[bobEphemeralKey getPublicKey]]; // ECDH(A0,B0)
  
  
  NSData* aliceSendingRKCK = [TSHKDF deriveKeyFromMaterial:aliceMasterKey outputLength:64 info:[@"WhisperText" dataUsingEncoding:NSASCIIStringEncoding] salt:[NSData data]]; // Initial RK
  
  
  // Now alice will create a sending a few more messages along side the next ratchet key A1. We can already do this as we have Bob's B1
  // She generates a future ratchet chain
  TSECKeyPair *A1 = [TSECKeyPair keyPairGenerateWithPreKeyId:0]; // generate A1 for ratchet on sending chain
  NSData* aliceSendingRKCK0 = [TSAxolotlRatchet newRootKeyAndChainKeyWithTheirPublicEphemeral:[bobEphemeralKey getPublicKey] fromMyNewEphemeral:A1 withExistingRK:[aliceSendingRKCK firstHalfsOfData]]; // ECDH(A1,B0)
  
  NSData* aliceSendingMKCK0 = [TSAxolotlRatchet nextMessageAndChainKeyFromChainKey:[aliceSendingRKCK0 secondHalfOfData]]; //CK-A1-B0 MK0
  // She sends messages on the current chain, along with A1 to be used on her next receiving chain
  NSData* aliceSendingMKCK1 = [TSAxolotlRatchet nextMessageAndChainKeyFromChainKey:[aliceSendingMKCK0 secondHalfOfData]]; //CK-A1-B0 MK1
  NSData* aliceSendingMKCK2 = [TSAxolotlRatchet nextMessageAndChainKeyFromChainKey:[aliceSendingMKCK1 secondHalfOfData]]; //CK-A1-B0 MK2

  // Bob gets these messages, and is ready to decrypt
  NSData* bobMasterKey = [self.ratchet masterKeyBob:bobIdentityKey ourEphemeral:bobEphemeralKey theirIdentityPublicKey:[aliceIdentityKey getPublicKey] theirEphemeralPublicKey:[aliceEphemeralKey getPublicKey]]; // ECDH(A0,B0)
  XCTAssertTrue([aliceMasterKey isEqualToData:bobMasterKey], @"alice and bob master keys not equal");

  
  NSData* bobReceivingRKCK = [TSHKDF deriveKeyFromMaterial:bobMasterKey outputLength:64 info:[@"WhisperText" dataUsingEncoding:NSASCIIStringEncoding] salt:[NSData data]]; // inital RK
  XCTAssertTrue([aliceSendingRKCK isEqualToData:bobReceivingRKCK], @"alice and bob initial RK and CK not equal");

  // he has A1 public so he's able to then generate the sending chain of Alice's (his receiving chain)
  NSData* bobReceivingRKCK0 = [TSAxolotlRatchet newRootKeyAndChainKeyWithTheirPublicEphemeral:[A1 getPublicKey] fromMyNewEphemeral:bobEphemeralKey withExistingRK:[bobReceivingRKCK firstHalfsOfData]]; // ECDH(A1,B0)
  XCTAssertTrue([aliceSendingRKCK0 isEqualToData:bobReceivingRKCK0], @"alice and bob first ratchet RK CK not equal");
  // Bob's next sending chain will use A1 and his own B1 to generate a message
  TSECKeyPair *B1 = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  NSData* bobSendingRKCK0 = [TSAxolotlRatchet newRootKeyAndChainKeyWithTheirPublicEphemeral:[A1 getPublicKey] fromMyNewEphemeral:B1 withExistingRK:[bobReceivingRKCK0 firstHalfsOfData]];

  
  
  // CK-A1-B0
  NSData* bobReceivingMKCK0 = [TSAxolotlRatchet nextMessageAndChainKeyFromChainKey:[bobReceivingRKCK0 secondHalfOfData]]; //CK-A1-B0 MK0
  NSData* bobReceivingMKCK1 = [TSAxolotlRatchet nextMessageAndChainKeyFromChainKey:[bobReceivingMKCK0 secondHalfOfData]]; //CK-A1-B0 MK1
  NSData* bobReceivingMKCK2 = [TSAxolotlRatchet nextMessageAndChainKeyFromChainKey:[bobReceivingMKCK1 secondHalfOfData]]; //CK-A1-B0 MK2


  XCTAssertTrue([aliceSendingMKCK0 isEqualToData:bobReceivingMKCK0], @"alice and bob first message on chain MK CK not equal");
  XCTAssertTrue([aliceSendingMKCK1 isEqualToData:bobReceivingMKCK1], @"alice and bob second message on chain MK CK not equal");
  XCTAssertTrue([aliceSendingMKCK2 isEqualToData:bobReceivingMKCK2], @"alice and bob third message on chain MK CK not equal");
  // Testing the cipher and mac key generation
  TSWhisperMessageKeys* aliceSendingKeysMK0 = [self.ratchet  deriveTSWhisperMessageKeysFromMessageKey:[aliceSendingMKCK0 firstHalfsOfData]];
  TSWhisperMessageKeys* bobReceivingKeysMK0 = [self.ratchet  deriveTSWhisperMessageKeysFromMessageKey:[bobReceivingMKCK0 firstHalfsOfData]];
  XCTAssertTrue([aliceSendingKeysMK0.cipherKey isEqualToData:bobReceivingKeysMK0.cipherKey], @"cipher keys alice and bob for MK0 not equal");
  XCTAssertTrue([aliceSendingKeysMK0.macKey isEqualToData:bobReceivingKeysMK0.macKey], @"mac keys alice and bob for MK0 not equal");
  XCTAssertTrue([aliceSendingKeysMK0.cipherKey length]==32, @"cipher key wrong size");
  XCTAssertTrue([aliceSendingKeysMK0.macKey length]==32, @"mac key wrong size");
  
  
  // Alice, on receiving B1 and the message encrypted with it updates her receiving chain with A1,B1 (decrypted the received message on that chain) and her sending chain with a new public ephemeral of hers A2
  NSData* aliceReceivingRKCK0 = [TSAxolotlRatchet newRootKeyAndChainKeyWithTheirPublicEphemeral:[B1 getPublicKey] fromMyNewEphemeral:A1 withExistingRK:[aliceSendingRKCK0 firstHalfsOfData]];
  XCTAssertTrue([aliceReceivingRKCK0 isEqualToData:bobSendingRKCK0], @"alice and bobs chains are out of sync");
  
  // She also updates her sending chain with a new public ephemeral of hers A2

  TSECKeyPair *A2 = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  NSData* aliceSendingRKCK1 = [TSAxolotlRatchet newRootKeyAndChainKeyWithTheirPublicEphemeral:[B1 getPublicKey] fromMyNewEphemeral:A2 withExistingRK:[aliceReceivingRKCK0 firstHalfsOfData]];
  // She can send this to Bob with a message encrypted on it, and he will be able to decrypt
  
  
  // Bob on receipt of A2 and a message encrypted with A2 can update his receiving chain and generate a new sending chain
  
  NSData* bobReceivingRKCK1 = [TSAxolotlRatchet newRootKeyAndChainKeyWithTheirPublicEphemeral:[A2 getPublicKey] fromMyNewEphemeral:B1 withExistingRK:[bobSendingRKCK0 firstHalfsOfData]];
  XCTAssertTrue([bobReceivingRKCK1 isEqualToData:aliceSendingRKCK1], @"alice and bobs chains are out of sync");
  
  // He also updates his sending chain with a new public ephemeral of his B2
  
  TSECKeyPair *B2 = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  NSData* bobSendingRKCK1 = [TSAxolotlRatchet newRootKeyAndChainKeyWithTheirPublicEphemeral:[A2 getPublicKey] fromMyNewEphemeral:B2 withExistingRK:[bobReceivingRKCK1 firstHalfsOfData]];

  

}

@end
