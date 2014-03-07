//
//  MessagesManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 30/11/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesManager.h"
#import "TSAxolotlRatchet.hh"
#import "TSMessage.h"
#import "NSData+Base64.h"
#import "TSSubmitMessageRequest.h"
#import "TSMessagesDatabase.h"
#import "TSMessagesManager.h"
#import "TSAttachmentManager.h"
#import "TSKeyManager.h"
#import "Cryptography.h"
#import "TSMessage.h"
#import "TSMessagesDatabase.h"
#import "TSAttachment.h"
#import "IncomingPushMessageSignal.pb.hh"
#import "TSMessageSignal.hh"

@interface TSMessagesManager (){
    dispatch_queue_t queue;
}
@end

@implementation TSMessagesManager


+ (id)sharedManager {
    static TSMessagesManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        queue = dispatch_queue_create("TSMessageManagerQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void)sendMessage:(TSMessage*)message{
    dispatch_async(queue, ^{
        [TSMessagesDatabase storeMessage:message];
    }
    // For a given thread, the Axolotl Ratchet should find out what's the current messaging state to send the message.
                   
    
   
    TSWhisperMessageType messageType = TSPreKeyWhisperMessageType;
    
    TSAxolotlRatchet *ratchet = [[TSAxolotlRatchet alloc] initForThread:thread];
    
    switch (messageType) {
            
        case TSPreKeyWhisperMessageType:{
            // get a contact's prekey
            TSContact* contact = [ratchet.thread.participants objectAtIndex:0];
            [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRecipientPrekeyRequest alloc] initWithRecipient:contact] success:^(AFHTTPRequestOperation *operation, id responseObject) {
                switch (operation.response.statusCode) {
                    case 200:{
                        
                        NSLog(@"Prekey fetched :) ");
                        
                        // Extracting the recipients keying material from server payload
                        
                        NSData* theirIdentityKey = [NSData dataFromBase64String:[responseObject objectForKey:@"identityKey"]];
                        NSData* theirEphemeralKey = [NSData dataFromBase64String:[responseObject objectForKey:@"publicKey"]];
                        NSNumber* theirPrekeyId = [responseObject objectForKey:@"keyId"];
                        
                        NSLog(@"We got the prekeys! %@", responseObject);
                        
                        // remove the leading "0x05" byte as per protocol specs
                        if (theirEphemeralKey.length == 33) {
                            theirEphemeralKey = [theirEphemeralKey subdataWithRange:NSMakeRange(1, 32)];
                        }
                        
                        // remove the leading "0x05" byte as per protocol specs
                        if (theirIdentityKey.length == 33) {
                            theirIdentityKey = [theirIdentityKey subdataWithRange:NSMakeRange(1, 32)];
                        }
                        
                        // Retreiving my keying material to construct message
                        
                        TSECKeyPair *currentEphemeral = [ratchet ratchetSetupFirstSender:theirIdentityKey theirEphemeralKey:theirEphemeralKey];
                        NSData *encryptedMessage = [ratchet encryptTSMessage:message withKeys:[ratchet nextMessageKeysOnChain:TSSendingChain] withCTR:[NSNumber numberWithInt:0]];
                        TSECKeyPair *nextEphemeral = [TSMessagesDatabase ephemeralOfSendingChain:thread]; // nil
                        NSData* encodedPreKeyWhisperMessage = [TSPreKeyWhisperMessage constructFirstMessage:encryptedMessage theirPrekeyId:theirPrekeyId myCurrentEphemeral:currentEphemeral myNextEphemeral:nextEphemeral];
                        [TSAxolotlRatchet receiveMessage:encodedPreKeyWhisperMessage];
                        [[TSMessagesManager sharedManager] submitMessageTo:message.recipientId message:[encodedPreKeyWhisperMessage base64EncodedString] ofType:TSPreKeyWhisperMessageType];
                        
                        // nil
                        break;
                    }
                    default:
                        DLog(@"error sending message");
#warning Add error handling if not able to get contacts prekey
                        break;
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning right now it is not succesfully processing returned response, but is giving 200
                DLog(@"Not a 200");
                
            }];
            
            break;
        }
        case TSEncryptedWhisperMessageType: {
            // unsupported
            break;
        }
        case TSUnencryptedWhisperMessageType: {
            NSString *serializedMessage= [[TSPushMessageContent serializedPushMessageContent:message] base64EncodedStringWithOptions:0];
            [[TSMessagesManager sharedManager] submitMessageTo:message.recipientId message:serializedMessage ofType:messageType];
            break;
        }
        default:
            break;
    }
}

-(void)receiveMessage:(NSData*)data{
    
    dispatch_async(queue, ^{
        // Do some cool stuff

    NSData* decryptedPayload = [Cryptography decryptAppleMessagePayload:data withSignalingKey:[TSKeyManager getSignalingKeyToken]];
    TSMessageSignal *messageSignal = [[TSMessageSignal alloc] initWithData:decryptedPayload];
    
    TSThread *thread = [TSThread threadWithContacts: @[[[TSContact alloc] initWithRegisteredID:messageSignal.source]]save:YES];
    
    TSAxolotlRatchet *ratchet = [[TSAxolotlRatchet alloc] initForThread:thread];
    
    TSMessage* message;
    
    // Get or create session
    
    
    switch (messageSignal.contentType) {
            
        case TSPreKeyWhisperMessageType: {
            
            TSPreKeyWhisperMessage* preKeyMessage = (TSPreKeyWhisperMessage*)messageSignal.message;
            TSEncryptedWhisperMessage* whisperMessage = (TSEncryptedWhisperMessage*)preKeyMessage.message;
            
            
            RATCHET !
            ciphertextMessage.verifyMac(messageKeys.getMacKey());
            
            byte[] plaintext = getPlaintext(messageKeys, ciphertextMessage.getBody());
            
            // Ratchet - Get plaintext method
            [ratchet ratchetSetupFirstReceiver:preKeyMessage.identityKey theirEphemeralKey:preKeyMessage.baseKey withMyPrekeyId:preKeyMessage.preKeyId];
            [ratchet updateChainsOnReceivedMessage:whisperMessage.ephemeralKey];
            
        
            
            TSWhisperMessageKeys* decryptionKeys =  [ratchet nextMessageKeysOnChain:TSReceivingChain];
            NSData* tsMessageDecryption = [Cryptography decryptCTRMode:whisperMessage.message withKeys:decryptionKeys withCounter:whisperMessage.counter];
            
            message = [TSMessage messageWithContent:[[NSString alloc] initWithData:tsMessageDecryption encoding:NSUTF8StringEncoding]
                                             sender:messageSignal.source
                                          recipient:[TSKeyManager getUsernameToken]
                                               date:messageSignal.timestamp];
            
            break;
        }
            
        case TSEncryptedWhisperMessageType: {
            TSEncryptedWhisperMessage* whisperMessage = (TSEncryptedWhisperMessage*)messageSignal.message;
            [ratchet updateChainsOnReceivedMessage:whisperMessage.ephemeralKey];
            TSWhisperMessageKeys* decryptionKeys =  [ratchet nextMessageKeysOnChain:TSReceivingChain];
            NSData* tsMessageDecryption = [Cryptography decryptCTRMode:whisperMessage.message withKeys:decryptionKeys withCounter:whisperMessage.counter];
            
            message = [TSMessage messageWithContent:[[NSString alloc] initWithData:tsMessageDecryption encoding:NSUTF8StringEncoding]
                                             sender:messageSignal.source
                                          recipient:[TSKeyManager getUsernameToken]
                                               date:messageSignal.timestamp];
            
            break;
        }
            
        case TSUnencryptedWhisperMessageType: {
            TSPushMessageContent* messageContent = [[TSPushMessageContent alloc] initWithData:messageSignal.message.message];
            message = [messageSignal getTSMessage:messageContent];
            break;
        }
            
        default:
            // TODO: Missing error handling here ? Otherwise we're storing a nil message
            @throw [NSException exceptionWithName:@"Invalid state" reason:@"This should not happen" userInfo:nil];
            break;
    }
    
    [TSMessagesDatabase storeMessage:message fromThread:[TSThread threadWithContacts: @[[[TSContact alloc]  initWithRegisteredID:message.senderId]]save:YES]];
        
    });

}


- (void)receiveMessagePush:(NSDictionary *)pushInfo{
    
#warning verify if database is open, if not, save somewhere else before processing.
    
    [TSAxolotlRatchet receiveMessage:[NSData  dataFromBase64String:[pushInfo objectForKey:@"m"]]];
    // TO-DO Save message here if works.
}

-(void) sendMessage:(TSMessage*)message onThread:(TSThread*)thread{
    [TSAxolotlRatchet sendMessage:message onThread:thread];
}

-(void) submitMessageTo:(NSString*)recipientId message:(NSString*)serializedMessage ofType:(TSWhisperMessageType)messageType {
    
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSSubmitMessageRequest alloc] initWithRecipient:recipientId message:serializedMessage ofType:messageType] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        switch (operation.response.statusCode) {
            case 200:{
                // Awesome! We consider the message as sent! (Improvement: add flag in DB for sent)
                
                UIAlertView *message = [[UIAlertView alloc]initWithTitle:@"Message was sent" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [message show];
                
                break;
            }
                
            default:
                DLog(@"error sending message");
#warning Add error handling if not able to get contacts prekey
                // Use last resort key
                break;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning right now it is not succesfully processing returned response, but is giving 200
        DLog(@"failure %d, %@, %@",operation.response.statusCode,operation.response.description,[[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);
        [[NSNotificationCenter defaultCenter] postNotificationName:TSDatabaseDidUpdateNotification object:nil userInfo:@{@"messageType":@"send"}];
        
    }];
    
}


@end
