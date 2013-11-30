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
#include <CommonCrypto/CommonHMAC.h>

#import "NSData+Conversion.h"
#import "KeychainWrapper.h"
#import "Constants.h"
#import <RNCryptor/RNEncryptor.h>
#import <RNCryptor/RNDecryptor.h>

#include "NSString+Conversion.h"
#include "NSData+Base64.h"
#include "ECKeyPair.h"
#import "EncryptedDatabase.h"
#import "TSRegisterPrekeysRequest.h"
#import "FilePath.h"


@implementation Cryptography


+(NSString*) generateNewAccountAuthenticationToken {
  NSMutableData* authToken = [Cryptography generateRandomBytes:16];
  NSString* authTokenPrint = [[NSData dataWithData:authToken] hexadecimalString];
  return authTokenPrint;
}

+(NSString*) generateNewSignalingKeyToken {
   /*The signalingKey is 32 bytes of AES material (256bit AES) and 20 bytes of Hmac key material (HmacSHA1) concatenated into a 52 byte slug that is base64 encoded. */
  NSMutableData* signalingKeyToken = [Cryptography generateRandomBytes:52];
  NSString* signalingKeyTokenPrint = [[NSData dataWithData:signalingKeyToken] base64EncodedString];
  return signalingKeyTokenPrint;

}


+(NSMutableData*) generateRandomBytes:(int)numberBytes {
  NSMutableData* randomBytes = [NSMutableData dataWithLength:numberBytes];
  int err = 0;
  err = SecRandomCopyBytes(kSecRandomDefault,numberBytes,[randomBytes mutableBytes]);
  if(err != noErr) {
    @throw [NSException exceptionWithName:@"random problem" reason:@"problem generating the random " userInfo:nil];
  }
  return randomBytes;
}

+(void) generateAndStoreIdentityKey {
  /* 
   An identity key is an ECC key pair that you generate at install time. It never changes, and is used to certify your identity (clients remember it whenever they see it communicated from other clients and ensure that it's always the same).
   
   In secure protocols, identity keys generally never actually encrypt anything, so it doesn't affect previous confidentiality if they are compromised. The typical relationship is that you have a long term identity key pair which is used to sign ephemeral keys (like the prekeys).
   */
  EncryptedDatabase *cryptoDB = [EncryptedDatabase database];
  ECKeyPair *identityKey = [ECKeyPair createAndGeneratePublicPrivatePair:-1];
  [cryptoDB storeIdentityKey:identityKey];

}

+ (NSData*) getMasterSecretKey:(NSString*) userPassword {
  #warning TODO: verify the settings of RNCryptor to assert that what is going on in encryption/decryption is exactly what we want
  // PBKDF2 password (key)
  // encrypt  using AES256 of that with
  // IV=16random bytes
  //ciphertext=AES in CBC mode with key from PBKDF2
  // MAC =HMACshaw1(cipertext||IV) with key from PBKDF2
  // store IV||ciphertext||mac(IV||ciphertext)
  // decryption is AES256-1(ciphertext,IV) after verifying the MAC

  NSData* masterSecretPasswordEncrypted = [NSData dataFromBase64String:[Cryptography getEncryptedMasterSecretKey]];
  NSData* masterSecretPassword = [Cryptography AES256Decryption:masterSecretPasswordEncrypted withPassword:userPassword];
  if(!masterSecretPassword) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error entering user password" message:@"database will not open" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
  }
  return masterSecretPassword;
}
      
+ (void) generateAndStoreMasterSecretPassword:(NSString*) userPassword {
  NSData *masterSecretPassword =[Cryptography generateRandomBytes:36];

  NSData *masterSecretPasswordEncrypted = [Cryptography AES256Encryption:masterSecretPassword withPassword:userPassword];
 
  [Cryptography storeEncryptedMasterSecretKey:[masterSecretPasswordEncrypted base64EncodedString]];
}



+(void) generateAndStoreNewPreKeys:(int)numberOfPreKeys{
  #warning generateAndStoreNewPreKeys not yet tested
  EncryptedDatabase *cryptoDB = [EncryptedDatabase database];
  int lastPrekeyCounter = [cryptoDB getLastPrekeyId];
  NSMutableArray *prekeys = [[NSMutableArray alloc] initWithCapacity:numberOfPreKeys];
  if(lastPrekeyCounter<0) {
    // Prekeys have never before been generated
    lastPrekeyCounter = arc4random() % 16777215; //16777215 is 0xFFFFFF
    [prekeys addObject:[ECKeyPair createAndGeneratePublicPrivatePair:16777215]]; // Key of last resoort
  }

  
  for( int i=0; i<numberOfPreKeys; i++) {
    [prekeys addObject:[ECKeyPair createAndGeneratePublicPrivatePair:++lastPrekeyCounter]];
  }
  [cryptoDB savePersonalPrekeys:prekeys];
  // Sending new prekeys to network
  
  [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRegisterPrekeysRequest alloc] initWithPrekeyArray:prekeys identityKey:[cryptoDB getIdentityKey]] success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
    switch (operation.response.statusCode) {
      case 200:
      case 204:
        DLog(@"Device registered prekeys");
        break;
        
      default:
        DLog(@"Issue registering prekeys response %d, %@",operation.response.statusCode,operation.response.description);
#warning Add error handling if not able to send the prekeys
        break;
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
    DLog(@"failure %d, %@",operation.response.statusCode,operation.response.description); 
  
  
  }];

  
}


#pragma mark Authentication Token

+ (BOOL) storeAuthenticationToken:(NSString*)token {
  return [KeychainWrapper createKeychainValue:token forIdentifier:authenticationTokenStorageId];
}


+ (NSString*) getAuthenticationToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:authenticationTokenStorageId];
}

#pragma mark Username (Phone number)

+ (BOOL) storeUsernameToken:(NSString*)token {
  return [KeychainWrapper createKeychainValue:token forIdentifier:usernameTokenStorageId];
}

+ (NSString*) getUsernameToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:usernameTokenStorageId];
}

#pragma mark Authorization Token

+ (NSString*) getAuthorizationToken {
    return [self getAuthorizationTokenFromAuthToken:[Cryptography getAuthenticationToken]];
}

+ (NSString*) getAuthorizationTokenFromAuthToken:(NSString*)authToken{
    NSLog(@"Username : %@ and AuthToken: %@", [Cryptography getUsernameToken], [Cryptography getAuthenticationToken] );
    return [NSString stringWithFormat:@"%@:%@",[Cryptography getUsernameToken],[Cryptography getAuthenticationToken]];
}

#pragma mark SignalingKey

+ (BOOL) storeSignalingKeyToken:(NSString*)token {
    return [KeychainWrapper createKeychainValue:token forIdentifier:signalingTokenStorageId];
}

+ (NSString*) getSignalingKeyToken {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:signalingTokenStorageId];
}

#pragma mark encrypted master secret key

+ (BOOL) storeEncryptedMasterSecretKey:(NSString*)token {
  return [KeychainWrapper createKeychainValue:token forIdentifier:encryptedMasterSecretKeyStorageId];
}

+ (NSString*) getEncryptedMasterSecretKey {
  return [KeychainWrapper keychainStringFromMatchingIdentifier:encryptedMasterSecretKeyStorageId];
}

+ (NSData*)computeMACDigestForString:(NSString*)input withSeed:(NSString*)seed {
  //  void CCHmac(CCHmacAlgorithm algorithm, const void *key, size_t keyLength, const void *data,
  //       size_t dataLength, void *macOut);
  const char *cInput = [input UTF8String];
  const char *cSeed = [seed UTF8String];
  unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA1, cSeed, strlen(cSeed), cInput,strlen(cInput),cHMAC);
  NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
  return HMAC;
  
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

+(NSString*)truncatedSHA1Base64EncodedWithoutPadding:(NSString*)string{
    
    NSMutableData *hashData = [NSMutableData dataWithLength:20];
    CC_SHA1([[string dataUsingEncoding:NSUTF8StringEncoding] bytes], [[string dataUsingEncoding:NSUTF8StringEncoding] length], [hashData mutableBytes]);
    NSData *truncatedData = [hashData subdataWithRange:NSMakeRange(0, 10)];

    return [[truncatedData base64EncodedString] stringByReplacingOccurrencesOfString:@"=" withString:@""];
}


+(NSData*) AES256Encryption:(NSData*) dataToEncrypt withPassword:(NSString*)password {

  NSError *error;
  NSData *encryptedData = [RNEncryptor encryptData:dataToEncrypt
                                      withSettings:kRNCryptorAES256Settings
                                          password:password
                                             error:&error];
  return encryptedData;
}
          

+(NSData*) AES256Decryption:(NSData*) dataToDecrypt withPassword:(NSString*)password {
 
  NSError *error;
  NSData *decryptedData  = [RNDecryptor decryptData:dataToDecrypt
                                       withPassword:password
                                              error:&error];
  if(!error) {
    return decryptedData;
   
  }
  else {
     return nil;
  }
  
}









@end
