//
//  Cryptography.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/26/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "Cryptography.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>
#import "NSData+Conversion.h"
#import "KeychainWrapper.h"
#import "Constants.h"
#include "NSString+Conversion.h"
#include "NSData+Base64.h"
#import "FilePath.h"

@implementation Cryptography


#pragma mark random bytes methods
+(NSMutableData*) generateRandomBytes:(int)numberBytes {
    /* used to generate db master key, and to generate signaling key, both at install */
    NSMutableData* randomBytes = [NSMutableData dataWithLength:numberBytes];
    int err = 0;
    err = SecRandomCopyBytes(kSecRandomDefault,numberBytes,[randomBytes mutableBytes]);
    if(err != noErr) {
        @throw [NSException exceptionWithName:@"random problem" reason:@"problem generating the random " userInfo:nil];
    }
    return randomBytes;
}




#pragma mark SHA1

+(NSString*)truncatedSHA1Base64EncodedWithoutPadding:(NSString*)string{
    /* used by TSContactManager to send hashed/truncated contact list to server */
    NSMutableData *hashData = [NSMutableData dataWithLength:20];
    CC_SHA1([[string dataUsingEncoding:NSUTF8StringEncoding] bytes], [[string dataUsingEncoding:NSUTF8StringEncoding] length], [hashData mutableBytes]);
    NSData *truncatedData = [hashData subdataWithRange:NSMakeRange(0, 10)];
    
    return [[truncatedData base64EncodedString] stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

+ (NSString*)computeSHA1DigestForString:(NSString*)input {
    // Here we are taking in our string hash, placing that inside of a C Char Array, then parsing it through the SHA1 encryption method.
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

#pragma makr SHA256
+(NSData*) computeSHA256:(NSData *)data truncatedToBytes:(int)truncatedBytes {
  uint8_t digest[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(data.bytes, data.length, digest);
  return [[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH] subdataWithRange:NSMakeRange(0, truncatedBytes)];
}


#pragma mark HMAC/SHA256
+(NSData*) computeSHA256HMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey{
    uint8_t ourHmac[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmac(kCCHmacAlgSHA256,
           [HMACKey bytes],
           [HMACKey length],
           [dataToHMAC bytes],
           [dataToHMAC  length],
           ourHmac);
    return [NSData dataWithBytes:ourHmac length:CC_SHA256_DIGEST_LENGTH];
}

+(NSData*) computeSHA1HMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey{
    uint8_t ourHmac[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmac(kCCHmacAlgSHA1,
           [HMACKey bytes],
           [HMACKey length],
           [dataToHMAC bytes],
           [dataToHMAC  length],
           ourHmac);
    return [NSData dataWithBytes:ourHmac length:CC_SHA256_DIGEST_LENGTH];
}


+(NSData*) truncatedSHA1HMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey truncation:(int)bytes{
    return [[Cryptography computeSHA1HMAC:dataToHMAC withHMACKey:HMACKey] subdataWithRange:NSMakeRange(0, bytes)];
}

+(NSData*) truncatedSHA256HMAC:(NSData*)dataToHMAC withHMACKey:(NSData*)HMACKey truncation:(int)bytes{
    return [[Cryptography computeSHA256HMAC:dataToHMAC withHMACKey:HMACKey] subdataWithRange:NSMakeRange(0, bytes)];
}


#pragma mark AES CBC Mode
+(NSData*)encryptCBCMode:(NSData*) dataToEncrypt withKey:(NSData*) key withIV:(NSData*) iv withVersion:(NSData*)version  withHMACKey:(NSData*) hmacKey withHMACType:(TSMACType)hmacType computedHMAC:(NSData**)hmac {
    /* AES256 CBC encrypt then mac
     Returns nil if encryption fails
     */
    size_t bufferSize           = [dataToEncrypt length] + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t bytesEncrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          [key bytes], [key length],
                                          [iv bytes],
                                          [dataToEncrypt bytes], [dataToEncrypt length],
                                          buffer, bufferSize,
                                          &bytesEncrypted);
    
    if (cryptStatus == kCCSuccess){
        NSData* encryptedData= [NSData dataWithBytesNoCopy:buffer length:bytesEncrypted];
        //compute hmac of version||encrypted data||iv
        NSMutableData *dataToHmac = [NSMutableData data];
        if(version!=nil) {
            [dataToHmac appendData:version];
        }
        [dataToHmac appendData:iv];
        [dataToHmac appendData:encryptedData];
        
        if(hmacType == TSHMACSHA1Truncated10Bytes) {
            *hmac = [Cryptography truncatedSHA1HMAC:dataToHmac withHMACKey:hmacKey truncation:10];
        }
        else if (hmacType == TSHMACSHA256Truncated10Bytes) {
            *hmac = [Cryptography truncatedSHA256HMAC:dataToHmac withHMACKey:hmacKey truncation:10];
        }
        
        return encryptedData;
    }
    free(buffer);
    return nil;
    
}



+(NSData*) decryptCBCMode:(NSData*) dataToDecrypt withKey:(NSData*) key withIV:(NSData*) iv withVersion:(NSData*)version withHMACKey:(NSData*) hmacKey  withHMACType:(TSMACType)hmacType forHMAC:(NSData *)hmac {
    /* AES256 CBC encrypt then mac
     
     Returns nil if hmac invalid or decryption fails
     */
    //verify hmac of version||encrypted data||iv
    NSMutableData *dataToHmac = [NSMutableData data ];
    if(version!=nil) {
        [dataToHmac appendData:version];
    }
    [dataToHmac appendData:iv];
    [dataToHmac appendData:dataToDecrypt];
    
    // verify hmac
    NSData* ourHmacData;
    if(hmacType == TSHMACSHA1Truncated10Bytes) {
        ourHmacData = [Cryptography truncatedSHA1HMAC:dataToHmac withHMACKey:hmacKey truncation:10];
    }
    else if (hmacType == TSHMACSHA256Truncated10Bytes) {
        ourHmacData = [Cryptography truncatedSHA256HMAC:dataToHmac withHMACKey:hmacKey truncation:10];
    }
    
    if(hmac == nil || ![ourHmacData isEqualToData:hmac] ) {
        return nil;
    }
    
    // decrypt
    size_t bufferSize           = [dataToDecrypt length] + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t bytesDecrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          [key bytes], [key length],
                                          [iv bytes],
                                          [dataToDecrypt bytes], [dataToDecrypt length],
                                          buffer, bufferSize,
                                          &bytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:bytesDecrypted];
    }
    
    free(buffer);
    return nil;
    
    
}

#pragma mark methods which use AES CBC
+(NSData*) decryptAppleMessagePayload:(NSData*)payload withSignalingKey:(NSString*)signalingKeyString{
    unsigned char version[1];
    unsigned char iv[16];
    NSUInteger ciphertext_length = ([payload length]-10-17)*sizeof(char);
    unsigned char *ciphertext =  (unsigned char*)malloc(ciphertext_length);
    unsigned char mac[10];
    [payload getBytes:version range:NSMakeRange(0, 1)];
    [payload getBytes:iv range:NSMakeRange(1, 16)];
    [payload getBytes:ciphertext range:NSMakeRange(17, [payload length]-10-17)];
    [payload getBytes:mac range:NSMakeRange([payload length]-10, 10)];
    
    NSData* signalingKey = [NSData dataFromBase64String:signalingKeyString];
    NSData* signalingKeyAESKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(0, 32)];
    NSData* signalingKeyHMACKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(32, 20)];
    return [Cryptography decryptCBCMode:[NSData dataWithBytesNoCopy:ciphertext length:ciphertext_length freeWhenDone:YES] withKey:signalingKeyAESKeyMaterial withIV:[NSData dataWithBytes:iv length:16] withVersion:[NSData dataWithBytes:version length:1] withHMACKey:signalingKeyHMACKeyMaterial withHMACType:TSHMACSHA256Truncated10Bytes forHMAC:[NSData dataWithBytes:mac length:10]];
    
}

+(NSData*) decryptAttachment:(NSData*) dataToDecrypt withKey:(NSData*) key {
    // key: 32 byte AES key || 32 byte Hmac-SHA256 key.
    NSData *encryptionKey = [key subdataWithRange:NSMakeRange(0, 32)];
    NSData *hmacKey = [key subdataWithRange:NSMakeRange(32, 32)];
    // dataToDecrypt: IV || Ciphertext || truncated MAC(IV||Ciphertext)
    NSData *iv = [dataToDecrypt subdataWithRange:NSMakeRange(0, 10)];
    NSData *encryptedAttachment = [dataToDecrypt subdataWithRange:NSMakeRange(10, [dataToDecrypt length]-10-10)];
    NSData *hmac = [dataToDecrypt subdataWithRange:NSMakeRange([dataToDecrypt length]-10, 10)];
    return [Cryptography decryptCBCMode:encryptedAttachment withKey:encryptionKey withIV:iv withVersion:nil withHMACKey:hmacKey withHMACType:TSHMACSHA256Truncated10Bytes  forHMAC:hmac];
}




+(NSData*) encryptAttachment:(NSData*) attachment withRandomKey:(NSData**)key{
    // generate
    // random 10 byte IV
    // key: 32 byte AES key || 32 byte Hmac-SHA256 key.
    // returns: IV || Ciphertext || truncated MAC(IV||Ciphertext)
    NSData* iv = [Cryptography generateRandomBytes:10];
    NSData* encryptionKey = [Cryptography generateRandomBytes:32];
    NSData* hmacKey = [Cryptography generateRandomBytes:32];
    
    // The concatenated key for storage
    NSMutableData *outKey = [NSMutableData data];
    [outKey appendData:encryptionKey];
    [outKey appendData:hmacKey];
    *key = [NSData dataWithData:outKey];
    
    NSData* computedHMAC;
    NSData* ciphertext = [Cryptography encryptCBCMode:attachment withKey:encryptionKey withIV:iv withVersion:nil withHMACKey:hmacKey withHMACType:TSHMACSHA256Truncated10Bytes computedHMAC:&computedHMAC];
    
    NSMutableData* encryptedAttachment = [NSMutableData data];
    [encryptedAttachment appendData:iv];
    [encryptedAttachment appendData:ciphertext];
    [encryptedAttachment appendData:computedHMAC];
    return encryptedAttachment;
}


#pragma mark AESCTR Mode

+(NSData*)encryptCTRMode:(NSData*)dataToEncrypt withKeys: (TSMessageKeys*)keys {
    
    /* AES256 CTR encrypt then mac
     Returns nil if hmac invalid or decryption fails
     */
    
    size_t bufferSize        = [dataToEncrypt length] + kCCBlockSizeAES128;
    NSMutableData * buffer   = [NSMutableData dataWithLength: bufferSize];
    size_t bytesEncrypted    = 0;
    
    // setting up cryptor
    CCCryptorStatus cryptStatus;
    CCCryptorRef cryptor;
    cryptStatus = CCCryptorCreateWithMode(kCCEncrypt, kCCModeCTR, kCCAlgorithmAES128,
                                          ccNoPadding, [[Cryptography counterFromNumber:[NSNumber numberWithInt:keys.counter]] bytes],
                                          [keys.cipherKey bytes], [keys.cipherKey length],
                                          NULL, 0, 0, kCCModeOptionCTR_BE, &cryptor);
    if (cryptStatus != kCCSuccess){
        return nil;
    }
    
    cryptStatus = CCCryptorUpdate(cryptor, [dataToEncrypt bytes], [dataToEncrypt length], [buffer mutableBytes], [buffer length], &bytesEncrypted);
    if (cryptStatus != kCCSuccess){
        return nil;
    }
    
    // Returns a non-mutable copy
    [buffer setLength:bytesEncrypted];
    return [buffer copy];
}



+(NSData*)decryptCTRMode:(NSData*)ciphertext withKeys:(TSMessageKeys*)keys{
    
    /* AES256 CTR encrypt then mac / validate mac then decrypt
     Returns nil if hmac invalid or decryption fails
     */
    
    // decrypt
    size_t bufferSize        = [ciphertext length] + kCCBlockSizeAES128;
    NSMutableData * buffer   = [NSMutableData dataWithLength: bufferSize];
    size_t bytesDecrypted    = 0;
    
    // setting up cryptor
    CCCryptorStatus cryptStatus;
    CCCryptorRef cryptor;
    
    cryptStatus = CCCryptorCreateWithMode(kCCDecrypt, kCCModeCTR, kCCAlgorithmAES128,
                                          ccNoPadding, [[Cryptography counterFromNumber:[NSNumber numberWithInt:keys.counter]] bytes], [keys.cipherKey bytes], [keys.cipherKey length],
                                          NULL, 0, 0, kCCModeOptionCTR_BE, &cryptor);
    if (cryptStatus != kCCSuccess){
        return nil;
    }
    
    cryptStatus = CCCryptorUpdate(cryptor, [ciphertext bytes], [ciphertext length], [buffer mutableBytes], [buffer length], &bytesDecrypted);
    if (cryptStatus != kCCSuccess){
        return nil;
    }
    
    // Returns a non-mutable copy
    [buffer setLength:bytesDecrypted];
    return [buffer copy];
}

+(NSData*) counterFromNumber:(NSNumber*)ctr {
    uint32_t ctrInt = (uint32_t)[ctr intValue];
    uint8_t bytes[16] = {0}	;
    bytes[3]=(uint8_t)ctrInt;
    bytes[2]=(uint8_t)(ctrInt>>8);
    bytes[1]=(uint8_t)(ctrInt>>16);
    bytes[0]=(uint8_t)(ctrInt>>24);
    NSData* counter= [NSData dataWithBytes:&bytes length:16];
    return counter;
}

@end
