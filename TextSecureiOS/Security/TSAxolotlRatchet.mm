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


@interface NSData (Split)
-(NSData*) firstHalfOfData;
-(NSData*) secondHalfOfData;

@end

@implementation NSData (Split)

-(NSData*) firstHalfOfData {
  int size = [self length]/2;
  return [self subdataWithRange:NSMakeRange(0, size)];
}
-(NSData*) secondHalfOfData {
  int size = [self length]/2;
  return [self subdataWithRange:NSMakeRange(size,size)];
}

@end

@implementation TSAxolotlRatchet 
-(id) initForThread:(TSThread*)threadForRatchet{
  if(self = [super init]) {
    self.thread = threadForRatchet;
  }
  return self;
}
#pragma mark public methods
+(void)sendMessage:(TSMessage*)message onThread:(TSThread*)thread ofType:(TSWhisperMessageType) messageType {
  [TSMessagesDatabase storeMessage:message];
#warning always sneding a prekey message for testing!
  messageType = TSPreKeyWhisperMessageType;
  TSAxolotlRatchet *ratchet = [[TSAxolotlRatchet alloc] initForThread:thread];
  switch (messageType) {
      
    case TSPreKeyWhisperMessageType:{
      // get a contact's prekey
      TSContact* contact = [[TSContact alloc] initWithRegisteredID:message.recipientId];
      TSThread* thread = [TSThread threadWithMeAndParticipantsByRegisteredIds:@[message.recipientId]];
      [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRecipientPrekeyRequest alloc] initWithRecipient:contact] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        switch (operation.response.statusCode) {
          case 200:{
            NSData* theirIdentityKey = [NSData dataFromBase64String:[responseObject objectForKey:@"identityKey"]];
            NSData* theirEphemeralKey = [NSData dataFromBase64String:[responseObject objectForKey:@"publicKey"]];
            NSNumber* theirPrekeyId = [responseObject objectForKey:@"keyId"];
            
            [ratchet ratchetSetupFirstSender:theirIdentityKey theirEphemeralKey:theirEphemeralKey];
            [ratchet newSendingChain:theirEphemeralKey];
            TSWhisperMessageKeys *encryptionKeys = [ratchet nextMessageKeysOnChain:TSSendingChain];
            NSData *encryptedMessage = [ratchet encryptTSMessage:message withKeys:encryptionKeys withCTR:[NSNumber numberWithInt:0]];
            TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc]
                                                                    initWithEphemeralKey:[TSMessagesDatabase
                                                                                          getEphemeralPublicKeyOfChain:thread onChain:TSSendingChain]
                                                                    previousCounter:[TSMessagesDatabase getPNs:thread]
                                                                    counter:[TSMessagesDatabase getNPlusPlus:thread onChain:TSSendingChain]
                                                                    encryptedMessage:encryptedMessage];
            TSPreKeyWhisperMessage *prekeyMessage = [[TSPreKeyWhisperMessage alloc]
                                                     initWithPreKeyId:theirPrekeyId
                                                     recipientPrekey:theirEphemeralKey
                                                     recipientIdentityKey:theirIdentityKey
                                                     message:[encryptedWhisperMessage serializedProtocolBuffer]];

            [[TSMessagesManager sharedManager]
              submitMessageTo:message.recipientId
              message:[[prekeyMessage serializedProtocolBuffer] base64EncodedString]
              ofType:messageType];
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
      
      break;
    }
    case TSEncryptedWhisperMessageType: {
      TSWhisperMessageKeys *encryptionKeys = [ratchet nextMessageKeysOnChain:TSSendingChain];
      NSData *encryptedMessageText = [ratchet encryptTSMessage:message withKeys:encryptionKeys withCTR:[TSMessagesDatabase getNPlusPlus:thread onChain:TSSendingChain]];
      TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc]
                                                            initWithEphemeralKey:[TSMessagesDatabase getEphemeralPublicKeyOfChain:thread onChain:TSSendingChain]
                                                            previousCounter:[TSMessagesDatabase getPNs:thread]
                                                            counter:[TSMessagesDatabase getN:thread onChain:TSReceivingChain] encryptedMessage:encryptedMessageText];
      [[TSMessagesManager sharedManager]
        submitMessageTo:message.recipientId
        message:[[encryptedWhisperMessage serializedProtocolBuffer] base64EncodedString]
        ofType:messageType];
      break;
    }
    case TSUnencryptedWhisperMessageType: {
      NSString *serializedMessage= [[TSPushMessageContent serializedPushMessageContent:message] base64Encoding];
      [[TSMessagesManager sharedManager] submitMessageTo:message.recipientId message:serializedMessage ofType:messageType];
      break;
    }
    default:
      break;
  }
  
  
}



+(void)recieveMessage:(NSData*)data {
  NSData* decryptedPayload=[Cryptography decryptAppleMessagePayload:data withSignalingKey:[TSKeyManager getSignalingKeyToken]];
  TSMessageSignal *messageSignal = [[TSMessageSignal alloc] initWithData:decryptedPayload];
  TSMessage* message;
  TSAxolotlRatchet *ratchet = [[TSAxolotlRatchet alloc] initForThread:[TSThread threadWithMeAndParticipantsByRegisteredIds: @[messageSignal.source]]];
  switch (messageSignal.contentType) {
    case TSPreKeyWhisperMessageType: {
      // parse buffers
      TSPreKeyWhisperMessage* preKeyMessage = (TSPreKeyWhisperMessage*)messageSignal.message; // TODO: THIS IS FULL OF NOTHING
      TSEncryptedWhisperMessage* whisperMessage = (TSEncryptedWhisperMessage*)preKeyMessage.message;
      //setup ratchet
      [ratchet ratchetSetupFirstReceiver:preKeyMessage.identityKey theirEphemeralKey:preKeyMessage.baseKey withMyPrekeyId:preKeyMessage.preKeyId];
      // use ratchet
      TSWhisperMessageKeys* decryptionKeys =  [ratchet nextMessageKeysOnChain:TSReceivingChain];
      NSData* tsMessageDecryption = [Cryptography decryptCTRMode:whisperMessage.message withKeys:decryptionKeys withCounter:whisperMessage.counter];
      // now we want to setup the next sending ratchet with their public ephemeral
      [ratchet newSendingChain:whisperMessage.ephemeralKey];
      message=[[TSMessage alloc] initWithMessage:[[NSString alloc] initWithData:tsMessageDecryption encoding:NSASCIIStringEncoding] sender:messageSignal.source recipient:[TSKeyManager getUsernameToken] sentOnDate:messageSignal.timestamp];
      
      break;
    }

    case TSEncryptedWhisperMessageType: {
      TSEncryptedWhisperMessage *whisperMessage = (TSEncryptedWhisperMessage*)messageSignal;
      TSWhisperMessageKeys *decryptionKeys;
      if(whisperMessage.counter ==0) {
        // sender created this chain with a new public ephemeral and this is the first message on chain
        decryptionKeys = [ratchet nextMessageKeysOnChain:TSReceivingChain];

        
        
      }
      else {
        #warning check here if it's from a previous chain by seeing if the ephemeralkey is on our last seen queue. in that case decryption will be a special case
        // Check if the ephemeral key is corresponds our recently receiving chains (last 5 used). if so use that chain
        // right now receiving more than one message on a chain is not supported
        message = nil;
      }
      NSData *decryptedMessageText = [Cryptography decryptCTRMode:whisperMessage.message withKeys:decryptionKeys withCounter:whisperMessage.counter];
      
      [ratchet newSendingChain:whisperMessage.ephemeralKey];
      message = [[TSMessage alloc] initWithMessage:[[NSString alloc] initWithData:decryptedMessageText encoding:NSASCIIStringEncoding] sender:messageSignal.source recipient: [TSKeyManager getUsernameToken] sentOnDate:messageSignal.timestamp];
      break;
    }
    case TSUnencryptedWhisperMessageType: {
      TSPushMessageContent* messageContent = [[TSPushMessageContent alloc] initWithData:messageSignal.message.message];
      message = [messageSignal getTSMessage:messageContent];
      break;
    }
    default:
      break;
  }
  message.recipientId = [TSKeyManager getUsernameToken];
  [TSMessagesDatabase storeMessage:message];
}


#pragma mark private methods
-(void) ratchetSetupFirstSender:(NSData*)theirIdentity theirEphemeralKey:(NSData*)theirEphemeral {
  /* after this we will have the CK of the Sending Chain */
  TSECKeyPair *ourIdentityKey = [TSUserKeysDatabase getIdentityKeyWithError:nil];
  TSECKeyPair *ourEphemeralKey = [TSECKeyPair keyPairGenerateWithPreKeyId:0];
  NSData* ourMasterKey = [self masterKeyAlice:ourIdentityKey ourEphemeral:ourEphemeralKey   theirIdentityPublicKey:theirIdentity theirEphemeralPublicKey:theirEphemeral]; // ECDH(A0,B0)
  [self deriveInitialRKFromMasterKey:ourMasterKey]; // Sets Initial RK
  // Now alice will create a sending a few more messages along side the next ratchet key A1. We can already do this as we have Bob's B1
  [self newRootKeyAndChainKeyWithTheirPublicEphemeral:theirEphemeral fromMyNewEphemeral:ourEphemeralKey onChain:TSSendingChain]; // ECDH(A1,B0)
}


-(void) ratchetSetupFirstReceiver:(NSData*)theirIdentityKey theirEphemeralKey:(NSData*)theirEphemeralKey withMyPrekeyId:(NSNumber*)preKeyId {
  /* after this we will have the CK of the Receiving Chain */
  TSECKeyPair *ourEphemeralKey = [TSUserKeysDatabase getPreKeyWithId:[preKeyId unsignedLongValue] error:nil];
  TSECKeyPair *ourIdentityKey =  [TSUserKeysDatabase getIdentityKeyWithError:nil];
  NSData* ourMasterKey = [self masterKeyBob:ourIdentityKey ourEphemeral:ourEphemeralKey theirIdentityPublicKey:theirIdentityKey theirEphemeralPublicKey:theirEphemeralKey];
  [self deriveInitialRKFromMasterKey:ourMasterKey]; // inital RK
  // we have A1 public so he's able to then generate the sending chain of Alice's (our receiving chain)
  
  [self newRootKeyAndChainKeyWithTheirPublicEphemeral:theirEphemeralKey fromMyNewEphemeral:ourEphemeralKey onChain:TSReceivingChain]; // ECDH(A1,B0)
}


-(TSECKeyPair*)newSendingChain:(NSData*)theirPublicEphemeral {
  TSECKeyPair *myNewEphemeral = [TSECKeyPair keyPairGenerateWithPreKeyId:0]; // generate A1 for ratchet on sending chain
  [self newRootKeyAndChainKeyWithTheirPublicEphemeral:theirPublicEphemeral fromMyNewEphemeral:myNewEphemeral onChain:TSSendingChain];
  [TSMessagesDatabase setEphemeralPublicKeyOfChain:[myNewEphemeral getPublicKey] onThread:self.thread onChain:TSSendingChain];
  return myNewEphemeral;
}


-(void)newReceivingChain:(NSData*)theirPublicEphemeral fromMyNewEphemeral:(TSECKeyPair*)myNewEphemeral {
  // he has A1 public so he's able to then generate the sending chain of Alice's (his receiving chain)
  [self newRootKeyAndChainKeyWithTheirPublicEphemeral:theirPublicEphemeral fromMyNewEphemeral:myNewEphemeral onChain:TSReceivingChain];
  [TSMessagesDatabase setEphemeralPublicKeyOfChain:theirPublicEphemeral onThread:self.thread onChain:TSReceivingChain];
}










-(NSData*) encryptTSMessage:(TSMessage*)message  withKeys:(TSWhisperMessageKeys *)messageKeys withCTR:(NSNumber*)counter{
  return [Cryptography encryptCTRMode:[message.message dataUsingEncoding:NSASCIIStringEncoding] withKeys:messageKeys withCounter:counter];
}


#pragma mark helper methods
-(NSData*)newRootKeyAndChainKeyWithTheirPublicEphemeral:(NSData*)theirPublicEphemeral fromMyNewEphemeral:(TSECKeyPair*)newEphemeral onChain:(TSChainType)chain {
  NSData* inputKeyMaterial = [newEphemeral generateSharedSecretFromPublicKey:theirPublicEphemeral];
  NSData* newRkCK  = [TSHKDF deriveKeyFromMaterial:inputKeyMaterial outputLength:64 info:[@"WhisperRatchet" dataUsingEncoding:NSASCIIStringEncoding] salt:[TSMessagesDatabase getRK:self.thread]];
  [TSMessagesDatabase setRK:[newRkCK firstHalfOfData] onThread:self.thread];
  [TSMessagesDatabase setCK:[newRkCK secondHalfOfData] onThread:self.thread onChain:chain];
  if(chain == TSSendingChain) {
    [TSMessagesDatabase setPNs:[TSMessagesDatabase getN:self.thread onChain:TSSendingChain] onThread:self.thread];
  }
  [TSMessagesDatabase setN:[NSNumber numberWithInt:0] onThread:self.thread onChain:chain];
  return newRkCK;
}
-(NSData*)masterKeyAlice:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
  NSMutableData *masterKey = [NSMutableData data];
  [masterKey appendData:[ourIdentityKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
  [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirIdentityPublicKey]];
  [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
  return masterKey;
}

-(NSData*)masterKeyBob:(TSECKeyPair*)ourIdentityKeyPair ourEphemeral:(TSECKeyPair*)ourEphemeralKeyPair theirIdentityPublicKey:(NSData*)theirIdentityPublicKey theirEphemeralPublicKey:(NSData*)theirEphemeralPublicKey {
  NSMutableData *masterKey = [NSMutableData data];
  [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirIdentityPublicKey]];
  [masterKey appendData:[ourIdentityKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
  [masterKey appendData:[ourEphemeralKeyPair generateSharedSecretFromPublicKey:theirEphemeralPublicKey]];
  return masterKey;
}


-(TSWhisperMessageKeys*)nextMessageKeysOnChain:(TSChainType)chain {
  NSData* CK = [TSMessagesDatabase getCK:self.thread onChain:chain];
  /* Chain Key Derivation */
  int hmacKeyMK = 0x01;
  int hmacKeyCK = 0x02;
  NSData* nextMK = [Cryptography computeHMAC:CK withHMACKey:[NSData dataWithBytes:&hmacKeyMK length:sizeof(hmacKeyMK)]];
  NSData* nextCK = [Cryptography computeHMAC:CK  withHMACKey:[NSData dataWithBytes:&hmacKeyCK length:sizeof(hmacKeyCK)]];
  [TSMessagesDatabase setCK:nextCK onThread:self.thread onChain:chain];
  [TSMessagesDatabase getNPlusPlus:self.thread onChain:chain];
  return [self deriveTSWhisperMessageKeysFromMessageKey:nextMK];
}

-(NSData*) deriveInitialRKFromMasterKey:(NSData*)masterKey {
  NSData* rkCK = [TSHKDF deriveKeyFromMaterial:masterKey outputLength:64 info:[@"WhisperText" dataUsingEncoding:NSASCIIStringEncoding] salt:[NSData data]];
  [TSMessagesDatabase setRK:[rkCK firstHalfOfData] onThread:self.thread];
}


-(TSWhisperMessageKeys*) deriveTSWhisperMessageKeysFromMessageKey:(NSData*)nextMessageKey_MK {
  NSData* newCipherKeyAndMacKey  = [TSHKDF deriveKeyFromMaterial:nextMessageKey_MK outputLength:64 info:[@"WhisperMessageKeys" dataUsingEncoding:NSASCIIStringEncoding]];
  NSData* cipherKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(0, 32)];
  NSData* macKey = [newCipherKeyAndMacKey subdataWithRange:NSMakeRange(32, 32)];
  // we want to return something here  or use this locally
  return [[TSWhisperMessageKeys alloc] initWithCipherKey:cipherKey macKey:macKey];
}




@end
