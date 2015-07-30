//
//  CryptographyTests.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/19/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#include <stdlib.h>
#import "Cryptography.h"
#import "NSData+Base64.h"
#import "NSString+Conversion.h"
#import "TSMessageSignal.hh"
#import "IncomingPushMessageSignal.pb.hh"
#import "TSEncryptedWhisperMessage.hh"
#import "TSPreKeyWhisperMessage.hh"
#import "TSPushMessageContent.hh"
@interface CryptographyTests : XCTestCase

@end

// To avoid + h files
@interface TSMessageSignal (Test)
+ (textsecure::IncomingPushMessageSignal *)deserialize:(NSData *)data;
+ (TSWhisperMessage*) getWhisperMessageForData:(NSData*) data ofType:(TSWhisperMessageType)contentType;
@end

@interface Cryptography (Test)
+(NSData*) truncatedSHA256HMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey truncation:(int)bytes;
+(NSData*)encryptCBCMode:(NSData*) dataToEncrypt withKey:(NSData*) key withIV:(NSData*) iv withVersion:(NSData*)version  withHMACKey:(NSData*) hmacKey withHMACType:(TSMACType)hmacType computedHMAC:(NSData**)hmac;
+(NSData*) decryptCBCMode:(NSData*) dataToDecrypt withKey:(NSData*) key withIV:(NSData*) iv withVersion:(NSData*)version withHMACKey:(NSData*) hmacKey  withHMACType:(TSMACType)hmacType forHMAC:(NSData *)hmac;
@end

@implementation CryptographyTests


-(void) testLocalDecryption {
    NSString* originalMessage = @"Hawaii is awesome";
    NSString* signalingKeyString = @"VJuRzZcwuY/6VjGw+QSPy5ROzHo8xE36mKwHNvkfyZ+mSPaDlSDcenUqavIX1Vwn\nRRIdrg==";
    NSData* signalingKey = [NSData dataFromBase64String:signalingKeyString];
    XCTAssertTrue([signalingKey length]==52, @"signaling key is not 52 bytes but %llu", (unsigned long long)[signalingKey length]);
    NSData* signalingKeyAESKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(0, 32)];
    NSData* signalingKeyHMACKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(32, 20)];
    NSData* iv = [Cryptography generateRandomBytes:16];
    NSData* version = [Cryptography generateRandomBytes:1];
    NSData* mac;
    //Encrypt
    
    NSData* encryption = [Cryptography encryptCBCMode:[originalMessage dataUsingEncoding:NSUTF8StringEncoding] withKey:signalingKeyAESKeyMaterial withIV:iv withVersion:version withHMACKey:signalingKeyHMACKeyMaterial withHMACType:TSHMACSHA1Truncated10Bytes computedHMAC:&mac]; //Encrypt
    
    NSMutableData *dataToHmac = [NSMutableData data ];
    [dataToHmac appendData:version];
    [dataToHmac appendData:iv];
    [dataToHmac appendData:encryption];
    
    
    NSData* expectedHmac = [Cryptography truncatedSHA1HMAC:dataToHmac withHMACKey:signalingKeyHMACKeyMaterial truncation:10];
    
    XCTAssertTrue([mac isEqualToData:expectedHmac], @"Hmac of encrypted data %@,  not equal to expected hmac %@", [mac base64EncodedString], [expectedHmac base64EncodedString]);
    
    NSData* decryption=[Cryptography decryptCBCMode:encryption withKey:signalingKeyAESKeyMaterial withIV:iv withVersion:version withHMACKey:signalingKeyHMACKeyMaterial withHMACType:TSHMACSHA1Truncated10Bytes forHMAC:mac];
                        
    NSString* decryptedMessage = [[NSString alloc] initWithData:decryption encoding:NSUTF8StringEncoding];
    XCTAssertTrue([decryptedMessage isEqualToString:originalMessage],  @"Decrypted message: %@ is not equal to original: %@",decryptedMessage,originalMessage);
    
}


-(void) testCTRModeDecryption {
    NSString* originalMessage = @"Hawaii is awesome";

    for(int i=0; i<20; i++) {
        NSData* lastEncryption = nil;
        TSMessageKeys * messageKeysMeta = [[TSMessageKeys alloc] initWithCipherKey:[Cryptography generateRandomBytes:32] macKey:[Cryptography generateRandomBytes:32] counter:0];
        for(int ctr = 0; ctr < 100; ctr++) {
            TSMessageKeys *messageKeys = [[TSMessageKeys alloc] initWithCipherKey:messageKeysMeta.cipherKey macKey:messageKeysMeta.macKey counter:ctr];

            NSData* encryption = [Cryptography encryptCTRMode:[originalMessage dataUsingEncoding:NSASCIIStringEncoding] withKeys:messageKeys];
            XCTAssertFalse([encryption isEqualToData:lastEncryption] , @"encryption is equal to a previous encryption! this shouldn't happen with different counters, ctr=%d",ctr);
            lastEncryption = encryption;
            NSData* decryption = [Cryptography decryptCTRMode:encryption withKeys:messageKeys];
            
            NSString* decryptedMessage = [[NSString alloc] initWithData:decryption encoding:NSASCIIStringEncoding];
            XCTAssertTrue([decryptedMessage isEqualToString:originalMessage],  @"Decrypted message: %@ is not equal to original: %@",decryptedMessage,originalMessage);
            XCTAssertFalse([[originalMessage dataUsingEncoding:NSASCIIStringEncoding] isEqualToData:encryption], @"ctr encryption did nothing, as it encrypted data equals the original data. this is to catch that doesn't happen-as it could be disabled for testing/debugging");
        }
    }
}


@end

