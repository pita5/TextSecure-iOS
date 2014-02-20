//
//  CryptographyTests.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/19/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Cryptography.h"
#import "Cryptography.h"
#import "NSData+Base64.h"
#import "NSString+Conversion.h"
#import "TSMessageSignal.hh"
#import "IncomingPushMessageSignal.pb.hh"
#import "TSUnencryptedWhisperMessage.hh"
#import "TSEncryptedWhisperMessage.hh"
#import "TSPreKeyWhisperMessage.hh"
#import "TSPushMessageContent.hh"
#import "TSWhisperMessageKeys.h"
@interface CryptographyTests : XCTestCase

@end

// To avoid + h files
@interface TSMessageSignal (Test)
+ (textsecure::IncomingPushMessageSignal *)deserialize:(NSData *)data;
+ (TSWhisperMessage*) getWhisperMessageForData:(NSData*) data ofType:(TSWhisperMessageType)contentType;
@end

@implementation CryptographyTests


-(void) testLocalDecryption {
  NSString* originalMessage = @"Hawaii is awesome";
  NSString* signalingKeyString = @"VJuRzZcwuY/6VjGw+QSPy5ROzHo8xE36mKwHNvkfyZ+mSPaDlSDcenUqavIX1Vwn\nRRIdrg==";
  NSData* signalingKey = [NSData dataFromBase64String:signalingKeyString];
  XCTAssertTrue([signalingKey length]==52, @"signaling key is not 52 bytes but %d",[signalingKey length]);
  NSData* signalingKeyAESKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(0, 32)];
  NSData* signalingKeyHMACKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(32, 20)];
  NSData* iv = [Cryptography generateRandomBytes:16];
  NSData* version = [Cryptography generateRandomBytes:1];
  NSData* mac;
  //Encrypt
  
  NSData* encryption = [Cryptography encrypt:[originalMessage dataUsingEncoding:NSASCIIStringEncoding] withKey:signalingKeyAESKeyMaterial withIV:iv withVersion:version withHMACKey:signalingKeyHMACKeyMaterial computedHMAC:&mac]; //Encrypt
  
  NSMutableData *dataToHmac = [NSMutableData data ];
  [dataToHmac appendData:version];
  [dataToHmac appendData:iv];
  [dataToHmac appendData:encryption];
  
  
  NSData* expectedHmac = [Cryptography truncatedHMAC:dataToHmac withHMACKey:signalingKeyHMACKeyMaterial truncation:10];
  
  XCTAssertTrue([mac isEqualToData:expectedHmac], @"Hmac of encrypted data %@,  not equal to expected hmac %@", [mac base64EncodedString], [expectedHmac base64EncodedString]);
  
  NSData* decryption=[Cryptography decrypt:encryption withKey:signalingKeyAESKeyMaterial withIV:iv withVersion:version withHMACKey:signalingKeyHMACKeyMaterial forHMAC:mac];
  NSString* decryptedMessage = [[NSString alloc] initWithData:decryption encoding:NSASCIIStringEncoding];
  XCTAssertTrue([decryptedMessage isEqualToString:originalMessage],  @"Decrypted message: %@ is not equal to original: %@",decryptedMessage,originalMessage);
  
}

-(void) testDecryptionFromServer {
  NSString* originalMessage = @"Hawaii is awesome";
  NSString* signalingKeyString = @"VJuRzZcwuY/6VjGw+QSPy5ROzHo8xE36mKwHNvkfyZ+mSPaDlSDcenUqavIX1Vwn\nRRIdrg==";
  XCTAssertTrue([[NSData dataFromBase64String:signalingKeyString] length]==52, @"signaling key is not 52 bytes but %d",[[NSData dataFromBase64String:signalingKeyString]  length]);
  NSString* tsServerResponse = @"Aexen2G8XJxCxN9fp6pcCAgepw3dhoGvP1w66L560Z4BKjnh8vInFnde0pPAJe/0y07EyrQwDI9ETGyPM9D3qT5wRu3Y7UWe4J3l";
  NSData *payload = [NSData dataFromBase64String:tsServerResponse];

  NSData *decryptedPayload = [Cryptography decryptAppleMessagePayload:payload withSignalingKey:signalingKeyString];

  TSMessageSignal *tsMessageSignal = [[TSMessageSignal alloc] initWithData:decryptedPayload];
  TSPushMessageContent* tsMessageContent = [[TSPushMessageContent alloc] initWithData:tsMessageSignal.message.message];
  TSMessage* tsMessage =  [tsMessageSignal getTSMessage:tsMessageContent];

  XCTAssertTrue([tsMessage.message  isEqualToString:originalMessage], @"Decrypted message: %@ is not equal to original: %@",tsMessage.message,originalMessage);
}


-(void) testCTRModeDecryption {
#warning write this
  NSString* originalMessage = @"Hawaii is awesome";
  TSWhisperMessageKeys * messageKeys = [[TSWhisperMessageKeys alloc] initWithCipherKey:[Cryptography generateRandomBytes:32] macKey:[Cryptography generateRandomBytes:32]];
  for(int i=0;i<20; i++) {
    int counter = arc4random();
    //Encrypt
    NSData* encryption = [Cryptography encryptCTRMode:[originalMessage dataUsingEncoding:NSASCIIStringEncoding] withKeys:messageKeys withCounter:[NSNumber numberWithInt:counter]];
    
    NSData* expectedHmac = [Cryptography truncatedHMAC:[encryption subdataWithRange:NSMakeRange(0, [encryption length]-8)] withHMACKey:messageKeys.macKey truncation:8];
    NSData* mac = [encryption subdataWithRange:NSMakeRange([encryption length]-8,8)];
    XCTAssertTrue([mac isEqualToData:expectedHmac], @"Hmac of encrypted data %@,  not equal to expected hmac %@", [mac base64EncodedString], [expectedHmac base64EncodedString]);
    
    NSData* decryption = [Cryptography decryptCTRMode:encryption withKeys:messageKeys withCounter:[NSNumber numberWithInt:counter]];
    
    NSString* decryptedMessage = [[NSString alloc] initWithData:decryption encoding:NSASCIIStringEncoding];
    XCTAssertTrue([decryptedMessage isEqualToString:originalMessage],  @"Decrypted message: %@ is not equal to original: %@",decryptedMessage,originalMessage);
    XCTAssertFalse([[originalMessage dataUsingEncoding:NSASCIIStringEncoding] isEqualToData:encryption], @"ctr encryption did nothing, as it encrypted data equals the original data. this is to catch that doesn't happen-as it could be disabled for testing/debugging");
  }
}


@end

