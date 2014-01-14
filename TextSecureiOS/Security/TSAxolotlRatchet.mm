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

@implementation TSAxolotlRatchet 
-(id) initForThread:(TSThread*)thread {
  
}
#pragma mark public methods
+(void)processIncomingMessage:(NSData*)data {
  NSData* decryptedPayload=[Cryptography decryptAppleMessagePayload:data withSignalingKey:[TSKeyManager getSignalingKeyToken]];
  TSMessageSignal *messageSignal = [[TSMessageSignal alloc] initWithData:decryptedPayload];
  TSMessage* message;
  TSAxolotlRatchet *ratchet = [[TSAxolotlRatchet alloc] initForThread:[TSThread threadWithMeAndParticipantsByRegisteredIds: @[messageSignal.source]]];
  switch (messageSignal.contentType) {
    case TSEncryptedWhisperMessageType: {

     
      TSEncryptedWhisperMessage *whisperMessage = (TSEncryptedWhisperMessage*)messageSignal;
      
      TSWhisperMessageKeys *decryptionKeys;
      if(whisperMessage.counter ==0) {
        // sender created this chain with a new public ephemeral and this is the first message on chain
        decryptionKeys = [ratchet nextMessagingKeysOnReceivingChain];
        //setup new receiving chain with new public ephemeral received
        [ratchet createNextRatchetReceivingWithTheirPublicEphemeral:whisperMessage.ephemeralKey];
        
      }
      else {
        #warning check here if it's from a previous chain by seeing if the ephemeralkey is on our last seen queue. in that case decryption will be a special case
        // Check if the ephemeral key is corresponds our recently receiving chains (last 5 used). if so use that chain
        // right now receiving more than one message on a chain is not supported
        message = nil;
      }
      
      
      NSData *decryptedMessageText = [Cryptography decryptCTRMode:whisperMessage.message withKeys:decryptionKeys withCounter:whisperMessage.counter];
      
      
      // setup new sending chain with new public ephemeral received
      [ratchet createNextRatchetSending:whisperMessage.ephemeralKey];
      
      return [[TSMessage alloc] initWithMessage:[[NSString alloc] initWithData:tsMessageDecryption encoding:NSASCIIStringEncoding] sender:messageSignal.source recipient: [TSKeyManager getUsernameToken] sentOnDate:messageSignal.timestamp];
      break;
    }
    case TSPreKeyWhisperMessageType: {
      // parse buffers
      TSPreKeyWhisperMessage* preKeyMessage = (TSPreKeyWhisperMessage*)messageSignal.message; // TODO: THIS IS FULL OF NOTHING
      TSEncryptedWhisperMessage* whisperMessage = (TSEncryptedWhisperMessage*)preKeyMessage.message;
      
      //setup ratchet
      [ratchet ratchetSetupFirstReceiver];
      [ratchet createNextRatchetReceivingWithTheirPublicEphemeral:preKeyMessage.baseKey]
      TSWhisperMessageKeys *decryptionKeys = [ratchet nextMessagingKeysOnSendingChain];
      
      // decrypt message under ratchet
      NSData* tsMessageDecryption = [Cryptography decryptCTRMode:whisperMessage.message withKeys:decryptionKeys withCounter:whisperMessage.counter];
      
      // now we want to setup the next sending ratchet with their public ephemeral
      [ratchet createNextRatchetSending:whisperMessage.ephemeralKey];
      message=[[TSMessage alloc] initWithMessage:[[NSString alloc] initWithData:tsMessageDecryption encoding:NSASCIIStringEncoding] sender:messageSignal.source recipient:[TSKeyManager getUsernameToken] sentOnDate:messageSignal.timestamp];
      
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


+(void)processOutgoingMessage:(TSMessage*)message onThread:(TSThread*)thread ofType:(TSWhisperMessageType) messageType {
  [TSMessagesDatabase storeMessage:message];
  #warning always sneding a prekey message for testing!
  messageType = TSPreKeyWhisperMessageType;
  TSAxolotlRatchet *ratchet = [[TSAxolotlRatchet alloc] initForThread:thread];
  switch (messageType) {
    case TSEncryptedWhisperMessageType: {
      TSWhisperMessageKeys *encryptionKeys = [ratchet nextMessagingKeysOnSendingChain];
      NSData *encryptedMessageText = [ratchet encryptTSMessage:message withKeys:encryptionKeys withCTR:0];
      TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:[TSMessagesDatabase getEphemeralPublicKeyOfChain:thread forParty:TSSender] previousCounter:[TSMessagesDatabase getPNs:thread] counter:[TSMessagesDatabase getNPlusPlus:thread forParty:TSSender] encryptedMessage:encryptedMessageText];
      [[TSMessagesManager sharedManager]  submitMessageTo:message.recipientId message:[[encryptedWhisperMessage serializedProtocolBuffer] base64EncodedString] ofType:messageType];
      break;
    }
    case TSPreKeyWhisperMessageType:{
      // get a contact's prekey
      TSContact* contact = [[TSContact alloc] initWithRegisteredID:message.recipientId];
      TSThread* thread = [TSThread threadWithMeAndParticipantsByRegisteredIds:@[message.recipientId]];
      [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRecipientPrekeyRequest alloc] initWithRecipient:contact] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        switch (operation.response.statusCode) {
          case 200:{
            // in init, do data from base64 string [NSData dataFromBase64String:
            // first message on thread
            [ratchet ratchetSetupFirstSender];
            [ratchet createNextRatchetSendingAndGetNewPublicEphemeral];
            TSWhisperMessageKeys *encryptionKeys = [ratchet nextMessagingKeysOnSendingChain];
            NSData *encryptedMessageText = [ratchet encryptTSMessage:message withKeys:encryptionKeys withCTR:0];
            
            // now we can setup a receiving message chain and send them info too
            [ratchet createNextRatchetReceivingWithTheirPublicEphemeral:[responseObject objectForKey:@"publicKey"]];
            
            TSEncryptedWhisperMessage *encryptedWhisperMessage = [[TSEncryptedWhisperMessage alloc] initWithEphemeralKey:[TSMessagesDatabase getEphemeralPublicKeyOfChain:thread forParty:TSReceiver] previousCounter:[TSMessagesDatabase getPNs:thread] counter:[TSMessagesDatabase getNPlusPlus:thread forParty:TSSender] encryptedMessage:encryptedMessageText];
            
            TSPreKeyWhisperMessage *prekeyMessage = [[TSPreKeyWhisperMessage alloc] initWithPreKeyId:[responseObject objectForKey:@"keyId"] recipientPrekey:[responseObject objectForKey:@"publicKey"] recipientIdentityKey:[responseObject objectForKey:@"identityKey"] message:[[encryptedWhisperMessage serializedProtocolBuffer] base64EncodedString]];

            
            [[TSMessagesManager sharedManager] submitMessageTo:message.recipientId message:[[prekeyMessage serializedProtocolBuffer] base64EncodedString] ofType:messageType];
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
      [[TSMessagesManager sharedManager] submitMessageTo:message.recipientId message:serializedMessage ofType:messageType];
      break;
    }
    default:
      break;
  }
  

}
#pragma mark private methods
-(void) ratchetSetupFirstSender {
  NSData* aliceMasterKey = [self masterKeyAlice:aliceIdentityKey ourEphemeral:aliceEphemeralKey   theirIdentityPublicKey:[bobIdentityKey getPublicKey] theirEphemeralPublicKey:[bobEphemeralKey getPublicKey]]; // ECDH(A0,B0)
  // Now alice will create a sending a few more messages along side the next ratchet key A1. We can already do this as we have Bob's B1
  // She generates a future ratchet chain
  TSECKeyPair *A1 = [TSECKeyPair keyPairGenerateWithPreKeyId:0]; // generate A1 for ratchet on sending chain
  NSData* aliceSendingRKCK0 = [self newRootKeyAndChainKeyWithTheirPublicEphemeral:[bobEphemeralKey getPublicKey] fromMyNewEphemeral:A1 withExistingRK:[aliceSendingRKCK firstHalfsOfData]]; // ECDH(A1,B0)
}


-(void) ratchetSetupFirstReceiver {
  NSData* bobReceivingRKCK = [TSHKDF deriveKeyFromMaterial:bobMasterKey outputLength:64 info:[@"WhisperText" dataUsingEncoding:NSASCIIStringEncoding] salt:[NSData data]]; // inital RK
  XCTAssertTrue([aliceSendingRKCK isEqualToData:bobReceivingRKCK], @"alice and bob initial RK and CK not equal");
  
  // he has A1 public so he's able to then generate the sending chain of Alice's (his receiving chain)
  NSData* bobReceivingRKCK0 = [self newRootKeyAndChainKeyWithTheirPublicEphemeral:[A1 getPublicKey] fromMyNewEphemeral:bobEphemeralKey withExistingRK:[bobReceivingRKCK firstHalfsOfData]]; // ECDH(A1,B0)
}


-(void)createNextRatchetSending:(NSData*)theirPublicEphemeral {
  // STORE THIS IN DB
  TSECKeyPair *A1 = [TSECKeyPair keyPairGenerateWithPreKeyId:0]; // generate A1 for ratchet on sending chain
  NSData* aliceSendingRKCK0 = [self newRootKeyAndChainKeyWithTheirPublicEphemeral:theirPublicEphemeral fromMyNewEphemeral:A1 withExistingRK:[TSMessagesDatabase getRK:self.thread]]; // ECDH(A1,B0)

  
  // TODO: store return [A1 getPublicKey];
  
}

-(void)createNextRatchetReceivingWithTheirPublicEphemeral:(NSData*)theirPublicEphemeral {
  // STORE THIS IN DB
  // he has A1 public so he's able to then generate the sending chain of Alice's (his receiving chain)
  NSData* bobReceivingRKCK0 = [self newRootKeyAndChainKeyWithTheirPublicEphemeral:[A1 getPublicKey] fromMyNewEphemeral:bobEphemeralKey withExistingRK:[bobReceivingRKCK firstHalfsOfData]]; // ECDH(A1,B0)
}

-(TSWhisperMessageKeys*) nextMessagingKeysOnSendingChain {
  NSData* aliceSendingMKCK0 = [self nextMessageAndChainKeyFromChainKey:[aliceSendingRKCK0 secondHalfOfData]];
  TSWhisperMessageKeys* aliceSendingKeysMK0 = [TSAxolotlRatchet  deriveTSWhisperMessageKeysFromMessageKey:[aliceSendingMKCK0 firstHalfsOfData]];
  return aliceSendingKeysMK0;
}


-(TSWhisperMessageKeys*) nextMessagingKeysOnReceivingChain {
  NSData* bobReceivingMKCK0 = [self nextMessageAndChainKeyFromChainKey:[bobReceivingRKCK0 secondHalfOfData]]; //CK-A1-B0 MK0
  TSWhisperMessageKeys* bobReceivingKeysMK0 = [self  deriveTSWhisperMessageKeysFromMessageKey:[bobReceivingMKCK0 firstHalfsOfData]];
  return bobReceivingKeysMK0;
}

-(NSData*) encryptTSMessage:(TSMessage*)message  withKeys:(TSWhisperMessageKeys *)messageKeys withCTR:(NSNumber*)counter{
  return [Cryptography encryptCTRMode:[message.message dataUsingEncoding:NSASCIIStringEncoding] withKeys:messageKeys withCounter:counter];
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






@end
