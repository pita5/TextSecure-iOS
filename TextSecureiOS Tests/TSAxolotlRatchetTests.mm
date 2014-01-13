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
@interface TSAxolotlRatchetTests : XCTestCase

@end


// To avoid + h files
@interface TSAxolotlRatchet (Test)

+(NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey;
+(NSData*)masterKeyBob:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey;

#pragma mark private test methods
+(NSData*)nextMessageAndChainKeyTest:(NSData*)CK;
@end


@implementation TSAxolotlRatchet (Test)

+(NSData*)nextMessageAndChainKeyTest:(NSData*)CK {
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

+(NSData*)newRootKeyMaterial:(NSData*)newReceivedEphemeral {
  NSData* inputKeyMaterial = TSECKeyPair* newEphemeralKeyPair=[TSECKeyPair keyPairGenerateWithPreKeyId:0];
;
  NSData* newRkCK  = [TSHKDF deriveKeyFromMaterial:inputKeyMaterial outputLength:64 info:[@"WhisperRatchet" dataUsingEncoding:NSASCIIStringEncoding]];
  NSData* newRootKey_RK = [newRkCK subdataWithRange:NSMakeRange(0, 32)];
  NSData* newChainKey_CK = [newRkCK subdataWithRange:NSMakeRange(32, 32)];
}

+(NSData*)newRootKeyMaterialFromTheirEphermalPublic:(NSData*)theirEphemeralPublic onThread:(TSThread*)thread forParty:(TSParty) party {
  return [[TSAxolotlRatchet generateNewEphemeralKeyPairOnThread:thread forParty:party] generateSharedSecretFromPublicKey:theirEphemeralPublic];

@end


@implementation TSAxolotlRatchetTests

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

-(void) testMasterKeyGeneration {
  TSECKeyPair *aliceIdentityKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *aliceEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *bobIdentityKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *bobEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  
  NSData* aliceMasterKey = [TSAxolotlRatchet masterKeyAlice:aliceIdentityKey ourEphemeral:aliceEphemeralKey   theirIdentityPublicKey:[bobIdentityKey getPublicKey] theirEphemeralPublicKey:[bobEphemeralKey getPublicKey]];
  
  
  NSData* bobMasterKey = [TSAxolotlRatchet masterKeyBob:bobIdentityKey ourEphemeral:bobEphemeralKey theirIdentityPublicKey:[aliceIdentityKey getPublicKey] theirEphemeralPublicKey:[aliceEphemeralKey getPublicKey]];
  XCTAssertTrue([aliceMasterKey isEqualToData:bobMasterKey], @"alice and bob master keys not equal");
}

-(void) testFirstRatchet {
  TSECKeyPair *aliceIdentityKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *aliceEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *bobIdentityKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  TSECKeyPair *bobEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  // ratchet alice
  NSData* aliceMasterKey = [TSAxolotlRatchet masterKeyAlice:aliceIdentityKey ourEphemeral:aliceEphemeralKey   theirIdentityPublicKey:[bobIdentityKey getPublicKey] theirEphemeralPublicKey:[bobEphemeralKey getPublicKey]];
  
  NSData* aliceSendingRKCK = [TSHKDF deriveKeyFromMaterial:aliceMasterKey outputLength:64 info:[@"WhisperText" dataUsingEncoding:NSASCIIStringEncoding] salt:[NSData data]];
  NSData* aliceSendingRK = [aliceSendingRKCK subdataWithRange:NSMakeRange(0, 32)];
  NSData* aliceSendingCK = [aliceSendingRKCK subdataWithRange:NSMakeRange(32, 32)];
  NSData* aliceMKCK0 = [TSAxolotlRatchet nextMessageAndChainKeyTest:aliceSendingRKCK];
 
  
  
  NSData* bobMasterKey = [TSAxolotlRatchet masterKeyBob:bobIdentityKey ourEphemeral:bobEphemeralKey theirIdentityPublicKey:[aliceIdentityKey getPublicKey] theirEphemeralPublicKey:[aliceEphemeralKey getPublicKey]];
  
  NSData* bobReceivingRKCK = [TSHKDF deriveKeyFromMaterial:bobMasterKey outputLength:64 info:[@"WhisperText" dataUsingEncoding:NSASCIIStringEncoding] salt:[NSData data]];
  NSData* bobReceivingRK = [bobReceivingRKCK subdataWithRange:NSMakeRange(0, 32)];
  NSData* bobReceivingCK = [bobReceivingRKCK subdataWithRange:NSMakeRange(32, 32)];
  NSData* bobMKCK0 = [TSAxolotlRatchet nextMessageAndChainKeyTest:bobReceivingRKCK];
  
  XCTAssertTrue([aliceSendingRK isEqualToData:bobReceivingRK], @"alice and bob RK's not equal");
  XCTAssertTrue([aliceSendingCK isEqualToData:bobReceivingCK], @"alice and bob CK's not equal");
  XCTAssertTrue([aliceMKCK0 isEqualToData:bobMKCK0], @"alice and bob MKCK's not equal");
  
  // Now alice sends a few more messages along side the next ratchet key A2
  TSECKeyPair *A2 = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  // She generates a future ratchet chaine
  NSData* aliceMKCK1 = [TSAxolotlRatchet nextMessageAndChainKeyTest:[aliceMKCK0 subdataWithRange:NSMakeRange(32, 32)]];
  NSData* aliceMKCK2 = [TSAxolotlRatchet nextMessageAndChainKeyTest:[aliceMKCK1 subdataWithRange:NSMakeRange(32, 32)]];
  
  
  
  // Bob receive's these out of order, receives M2 first (denoted by counter
  NSData* bobMKCK1 = [TSAxolotlRatchet nextMessageAndChainKeyTest:[bobMKCK0 subdataWithRange:NSMakeRange(32, 32)]];
  NSData* bobMKCK2 = [TSAxolotlRatchet nextMessageAndChainKeyTest:[bobMKCK1 subdataWithRange:NSMakeRange(32, 32)]];

  
  XCTAssertTrue([aliceMKCK2 isEqualToData:bobMKCK2], @"alice and bob MKCK's not equal");
  // Bob keeps the old chain around as he may use it, but uses a2 to derive a new receiving chain
}

@end
