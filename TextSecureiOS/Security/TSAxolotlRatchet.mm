//
//  TSAxolotlRatchet.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSAxolotlRatchet.hh"

#import "TSMessage.h"
#import "TSThread.h"
#import "TSContact.h"
#import "NSData+Base64.h"
#import "TSSubmitMessageRequest.h"
#import "TSMessagesManager.h"
#import "TSKeyManager.h"
#import "Cryptography.h"
#import "TSMessage.h"
#import "TSMessagesDatabase.h"
#import "TSUserKeysDatabase.h"
#import "TSThread.h"
#import "TSMessageSignal.hh"
#import "TSPushMessageContent.hh"
#import "TSWhisperMessage.hh"
#import "TSEncryptedWhisperMessage.hh"
#import "TSPreKeyWhisperMessage.hh"
#import "TSECKeyPair.h"
#import "TSRecipientPrekeyRequest.h"
#import "TSWhisperMessageKeys.h"
#import "TSHKDF.h"
#import "TSParticipants.h"


@implementation TSAxolotlRatchet 

#pragma mark public methods
+(void)processIncomingMessage:(NSData*)data {
  NSData* decryptedPayload=[Cryptography decryptAppleMessagePayload:data withSignalingKey:[TSKeyManager getSignalingKeyToken]];
  TSMessageSignal *messageSignal = [[TSMessageSignal alloc] initWithData:decryptedPayload];
  TSMessage* message = [TSAxolotlRatchet decryptReceivedMessageSignal:messageSignal];
  message.recipientId = [TSKeyManager getUsernameToken];
  [TSMessagesDatabase storeMessage:message];
}

+(void)processOutgoingMessage:(TSMessage*)message onThread:(TSThread*)thread ofType:(TSWhisperMessageType) messageType {
  [TSMessagesDatabase storeMessage:message];
#warning always sneding a prekey message for testing!
  messageType = TSPreKeyWhisperMessageType;
  switch (messageType) {
    case TSEncryptedWhisperMessageType: {
      NSData* currentMK = [TSAxolotlRatchet updateAndGetNextMessageKeyOnThread:thread forParty:TSSender];
      TSWhisperMessageKeys *encryptionKeys = [TSAxolotlRatchet deriveTSWhisperMessageKeysFromMessageKey:currentMK];
      TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc] init];
      encryptedWhisperMessage.ephemeralKey = [TSMessagesDatabase getEphemeralPublicKeyOfChain:thread forParty:TSSender];
      encryptedWhisperMessage.previousCounter=[TSMessagesDatabase getPNs:thread];
      encryptedWhisperMessage.counter = [TSMessagesDatabase getNPlusPlus:thread forParty:TSSender];
      encryptedWhisperMessage.message=[TSAxolotlRatchet encryptTSMessage:message withKeys:encryptionKeys withCTR:encryptedWhisperMessage.counter];
      NSString *serializedMessage = [[encryptedWhisperMessage serializedProtocolBuffer] base64EncodedString];
      
      [TSAxolotlRatchet submitMessageTo:message.recipientId message:serializedMessage ofType:messageType];
      break;
    }
    case TSPreKeyWhisperMessageType:{
      // get a contact's prekey
      TSContact* contact = [[TSContact alloc] initWithRegisteredID:message.recipientId];
      TSThread* thread = [TSThread threadWithMeAndParticipantsByRegisteredIds:@[message.recipientId]];
      [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRecipientPrekeyRequest alloc] initWithRecipient:contact] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        switch (operation.response.statusCode) {
          case 200:{
            
            TSPreKeyWhisperMessage *prekeyMessage = [[TSPreKeyWhisperMessage alloc] init];
            prekeyMessage.preKeyId = [responseObject objectForKey:@"keyId"];
            prekeyMessage.recipientPreKey = [NSData dataFromBase64String:[responseObject objectForKey:@"publicKey"]];
            prekeyMessage.recipientIdentityKey = [NSData dataFromBase64String:[responseObject objectForKey:@"identityKey"]];
            TSWhisperMessageKeys* encryptionKeys = [TSAxolotlRatchet initialRootKeyDerivation:prekeyMessage onThread:thread forParty:TSSender];
            TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc] init];
            encryptedWhisperMessage.ephemeralKey = [[TSAxolotlRatchet generateNewEphemeralKeyPairOnThread:thread forParty:TSSender] getPublicKey];
            encryptedWhisperMessage.previousCounter=[NSNumber numberWithInt:0];
            encryptedWhisperMessage.counter = [NSNumber numberWithInt:0];
            encryptedWhisperMessage.message=[TSAxolotlRatchet encryptTSMessage:message withKeys:encryptionKeys withCTR:0];
            prekeyMessage.message = [encryptedWhisperMessage serializedProtocolBuffer];
            NSString *serializedMessage = [[prekeyMessage serializedProtocolBuffer] base64EncodedString]; // should be serialized message
            [TSAxolotlRatchet submitMessageTo:message.recipientId message:serializedMessage ofType:messageType];
            break;
          }
          default:
            DLog(@"error sending message");
#warning Add error handling if not able to get contacts prekey
            break;
        }
      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning right now it is not succesfully processing returned response, but is giving 200
        
      }];
    }
      
      break;
    case TSUnencryptedWhisperMessageType: {
      NSString *serializedMessage= [[TSPushMessageContent serializedPushMessageContent:message] base64Encoding];
      [TSAxolotlRatchet submitMessageTo:message.recipientId message:serializedMessage ofType:messageType];
      break;
    }
    default:
      break;
  }
  

}
#pragma mark private methods


#pragma mark TSProtocol Methods
+(NSData*) encryptTSMessage:(TSMessage*)message  withKeys:(TSWhisperMessageKeys *)messageKeys withCTR:(NSNumber*)counter{
  return [Cryptography encryptCTRMode:[message.message dataUsingEncoding:NSASCIIStringEncoding] withKeys:messageKeys withCounter:counter];
}

+(TSMessage*) decryptReceivedMessageSignal:(TSMessageSignal*)messageSignal  {
  switch (messageSignal.contentType) {
    case TSEncryptedWhisperMessageType: {
      TSThread* thread =[TSThread threadWithMeAndParticipantsByRegisteredIds: @[messageSignal.source]];
      TSEncryptedWhisperMessage *whisperMessage = (TSEncryptedWhisperMessage*)messageSignal;
#warning check here if it's from a previous chain by seeing if the ephemeralkey is on our last seen queue
      [TSAxolotlRatchet newRootKeyDerivationFromNewPublicEphemeral:whisperMessage.ephemeralKey onThread:thread forParty:TSSender];
      NSData* messageKey = [TSAxolotlRatchet updateAndGetNextMessageKeyOnThread:thread forParty:TSReceiver];
      TSWhisperMessageKeys *decryptionKeys = [TSAxolotlRatchet deriveTSWhisperMessageKeysFromMessageKey:messageKey];
      NSData* tsMessageDecryption = [Cryptography decryptCTRMode:whisperMessage.message withKeys:decryptionKeys withCounter:whisperMessage.counter];
      return [[TSMessage alloc] initWithMessage:[[NSString alloc] initWithData:tsMessageDecryption encoding:NSASCIIStringEncoding] sender:messageSignal.source recipient: [TSKeyManager getUsernameToken] sentOnDate:messageSignal.timestamp];
      break;
    }
    case TSPreKeyWhisperMessageType: {
      
      TSThread* thread =[TSThread threadWithMeAndParticipantsByRegisteredIds: @[messageSignal.source]];
      
      
      TSPreKeyWhisperMessage* preKeyMessage = (TSPreKeyWhisperMessage*)messageSignal.message; // TODO: THIS IS FULL OF NOTHING
      TSEncryptedWhisperMessage* whisperMessage = (TSEncryptedWhisperMessage*)preKeyMessage.message;
      TSWhisperMessageKeys* decryptionKeys = [TSAxolotlRatchet initialRootKeyDerivation:preKeyMessage onThread:thread forParty:TSReceiver];
      NSData* tsMessageDecryption = [Cryptography decryptCTRMode:whisperMessage.message withKeys:decryptionKeys withCounter:whisperMessage.counter];
      return [[TSMessage alloc] initWithMessage:[[NSString alloc] initWithData:tsMessageDecryption encoding:NSASCIIStringEncoding] sender:messageSignal.source recipient:[TSKeyManager getUsernameToken] sentOnDate:messageSignal.timestamp];
      
      break;
    }
    case TSUnencryptedWhisperMessageType: {
      TSPushMessageContent* messageContent = [[TSPushMessageContent alloc] initWithData:messageSignal.message.message];
      return [messageSignal getTSMessage:messageContent];
      break;
    }
    default:
      break;
  }
  return nil;
}


+(void) submitMessageTo:(NSString*)recipientId message:(NSString*)serializedMessage ofType:(TSWhisperMessageType)messageType {
  
  [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSSubmitMessageRequest alloc] initWithRecipient:recipientId message:serializedMessage ofType:messageType] success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
    switch (operation.response.statusCode) {
      case 200:
        DLog(@"we have some success information %@",responseObject);
        // So let's encrypt a message using this
        break;
        
      default:
        DLog(@"error sending message");
#warning Add error handling if not able to get contacts prekey
        break;
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning right now it is not succesfully processing returned response, but is giving 200
    DLog(@"failure %d, %@, %@",operation.response.statusCode,operation.response.description,[[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);
    [[NSNotificationCenter defaultCenter] postNotificationName:TSDatabaseDidUpdateNotification object:nil userInfo:@{@"messageType":@"send"}];
    
  }];
  
}
#pragma mark - AxolotlKeyAgreement protocol methods

+(TSWhisperMessageKeys*)initialRootKeyDerivation:(TSPreKeyWhisperMessage*)keyAgreementMessage onThread:(TSThread*)thread forParty:(TSParty) party {
  /* Initial Root Key */
  NSData* masterKey;
  switch (party) {
    case TSSender: {
      // TSPrekeyWhisperMessage comes pre-populated with their prekey/ephemeral key/base key and their identity key
    TSECKeyPair *ourIdentityKey = [TSUserKeysDatabase getIdentityKeyWithError:nil];
    TSECKeyPair *ourEphemeralKey = [TSAxolotlRatchet generateNewEphemeralKeyPairOnThread:thread forParty:party];
    
    
    masterKey = [TSAxolotlRatchet masterKeyAlice:ourIdentityKey ourEphemeral:ourEphemeralKey theirIdentityPublicKey:keyAgreementMessage.recipientIdentityKey theirEphemeralPublicKey:keyAgreementMessage.recipientPreKey];
      // TSPrekeyWhisperMessage comes we populate the TSPrekeyWhisperMessage instead with our public ephemeral key/base key and their identity key
      [TSMessagesDatabase setEphemeralPublicKeyOfChain:[ourEphemeralKey getPublicKey]  onThread:thread forParty:party];
      keyAgreementMessage.baseKey = [ourEphemeralKey getPublicKey];
      keyAgreementMessage.identityKey = [ourIdentityKey getPublicKey];
      
      break;
    }
    case TSReceiver: {
      TSECKeyPair *ourEphemeralKey = [TSUserKeysDatabase getPreKeyWithId:[keyAgreementMessage.preKeyId unsignedLongValue] error:nil];
      TSECKeyPair *ourIdentityKey =  [TSUserKeysDatabase getIdentityKeyWithError:nil];
      [TSMessagesDatabase setEphemeralPublicKeyOfChain:[ourEphemeralKey getPublicKey]  onThread:thread forParty:party];
      masterKey=[TSAxolotlRatchet masterKeyBob:ourIdentityKey ourEphemeral:ourEphemeralKey theirIdentityPublicKey:keyAgreementMessage.baseKey theirEphemeralPublicKey:keyAgreementMessage.identityKey];
      break;
    }
    default:
      break;
  }
  
  /*
   The concatenated ECDHE shared secrets are then fed into HKDF to derive a 32 byte root key (RK) and 32 byte chain key (CK). HKDF is used with a salt of zero bytes and an info of the octet string "WhisperText".
   
   The first 32 bytes out of the HDKF are used for the root key (RK) and the second 32 bytes out are used for the chain key (CK).
   */
  NSData* rkCK = [TSHKDF deriveKeyFromMaterial:masterKey outputLength:64 info:[@"WhisperText" dataUsingEncoding:NSASCIIStringEncoding] salt:[NSData data]];
  NSData* rootKey_RK = [rkCK subdataWithRange:NSMakeRange(0, 32)];
  NSData* chainKey_CK = [rkCK subdataWithRange:NSMakeRange(32, 32)];
  
  [TSMessagesDatabase setRK:rootKey_RK onThread:thread];
  [TSMessagesDatabase setCK:chainKey_CK onThread:thread forParty:party];
  NSData* nextMessageKey_MK = [TSAxolotlRatchet updateAndGetNextMessageKeyOnThread:thread forParty:party];
  return [TSAxolotlRatchet deriveTSWhisperMessageKeysFromMessageKey:nextMessageKey_MK];
  
}

+(NSData*)updateAndGetNextMessageKeyOnThread:(TSThread*)thread forParty:(TSParty)party {
  NSData* currentChainKey_CK = [TSMessagesDatabase getCK:thread forParty:party];
  /* Chain Key Derivation */
  int hmacKeyMK = 0x01;
  int hmacKeyCK = 0x02;
  NSData* nextMessageKey_MK = [Cryptography computeHMAC:currentChainKey_CK  withHMACKey:[NSData dataWithBytes:&hmacKeyMK length:sizeof(hmacKeyMK)]];
  
  NSData* nextChainKey_CK = [Cryptography computeHMAC:currentChainKey_CK  withHMACKey:[NSData dataWithBytes:&hmacKeyCK length:sizeof(hmacKeyCK)]];
  [TSMessagesDatabase setCK:nextChainKey_CK onThread:thread forParty:party];
  return nextMessageKey_MK;
}

+(TSWhisperMessageKeys*) deriveTSWhisperMessageKeysFromMessageKey:(NSData*)nextMessageKey_MK {
  NSData* newCipherKeyAndMacKey  = [TSHKDF deriveKeyFromMaterial:nextMessageKey_MK outputLength:64 info:[@"WhisperMessageKeys" dataUsingEncoding:NSASCIIStringEncoding]];
  NSData* cipherKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(0, 32)];
  NSData* macKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(32, 32)];
  // we want to return something here  or use this locally
  return [[TSWhisperMessageKeys alloc] initWithCipherKey:cipherKey macKey:macKey];
}

+(void)newRootKeyDerivationFromNewPublicEphemeral:(NSData*)newPublicEphemeral_DHR onThread:(TSThread*)thread forParty:(TSParty)party {
  /* New Root Key Derivation */
  NSData* inputKeyMaterial = [TSAxolotlRatchet newRootKeyMaterialFromTheirEphermalPublic:newPublicEphemeral_DHR onThread:thread forParty:party];
  NSData* newRkCK  = [TSHKDF deriveKeyFromMaterial:inputKeyMaterial outputLength:64 info:[@"WhisperRatchet" dataUsingEncoding:NSASCIIStringEncoding]];
  NSData* newRootKey_RK = [newRkCK subdataWithRange:NSMakeRange(0, 32)];
  NSData* newChainKey_CK = [newRkCK subdataWithRange:NSMakeRange(32, 32)];
  [TSMessagesDatabase setPNs:0 onThread:thread];
  [TSMessagesDatabase setRK:newRootKey_RK onThread:thread];
  [TSMessagesDatabase setCK:newChainKey_CK onThread:thread forParty:party];
}

+(NSData*)newRootKeyMaterialFromTheirEphermalPublic:(NSData*)theirEphemeralPublic onThread:(TSThread*)thread forParty:(TSParty) party {
  return [[TSAxolotlRatchet generateNewEphemeralKeyPairOnThread:thread forParty:party] generateSharedSecretFromPublicKey:theirEphemeralPublic];
  
}


+(NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
  NSMutableData *masterKey = [NSMutableData data];
  [masterKey appendData:[ourIdentityKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
  [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirIdentityPublicKey]];
  [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
  return masterKey;
}

+(NSData*)masterKeyBob:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
  NSMutableData *masterKey = [NSMutableData data];
  [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirIdentityPublicKey]];
  [masterKey appendData:[ourIdentityKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
  [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
  return masterKey;
}

+(TSECKeyPair*)generateNewEphemeralKeyPairOnThread:(TSThread*)thread forParty:(TSParty)party{
  TSECKeyPair* newEphemeralKeyPair=[TSECKeyPair keyPairGenerateWithPreKeyId:0];
  [TSMessagesDatabase setEphemeralPublicKeyOfChain:[newEphemeralKeyPair getPublicKey] onThread:thread forParty:party];
  return newEphemeralKeyPair;
}

@end
