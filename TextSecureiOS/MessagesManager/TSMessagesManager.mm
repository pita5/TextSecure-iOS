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
#import "TSMessageOutgoing.h"
#import "TSMessagesDatabase.h"
#import "TSAttachment.h"
#import "IncomingPushMessageSignal.pb.hh"
#import "TSMessageSignal.hh"
#import "TSContact.h"
#import "TSPreKeyWhisperMessage.hh"
#import "TSRecipientPrekeyRequest.h"
#import "TSSession.h"
#import "NSData+TSKeyVersion.h"


@interface TSMessagesManager (){
    dispatch_queue_t queue;
}
@end

@implementation TSMessagesManager

- (void)scheduleMessageSend:(TSMessageOutgoing *)message
{
    [TSMessagesDatabase storeMessage:message];
    [self sendMessage:message];
}

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

-(void)sendMessage:(TSMessageOutgoing*)message{
    dispatch_async(queue, ^{
        TSContact *recipient = [TSMessagesDatabase contactForRegisteredID:message.recipientId];
        NSArray *sessions = [TSMessagesDatabase sessionsForContact:recipient];
        
        if ([sessions count] > 0) {
            for (TSSession *session in sessions){
                [[TSMessagesManager sharedManager] submitMessage:message to:message.recipientId serializedMessage:[[[TSAxolotlRatchet encryptMessage:message withSession:session] getTextSecureProtocolData] base64EncodedString] ofType:TSEncryptedWhisperMessageType];
            }
            
        } else{
            
            [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRecipientPrekeyRequest alloc] initWithRecipient:recipient] success:^(AFHTTPRequestOperation *operation, id responseObject) {
                switch (operation.response.statusCode) {
                    case 200:{
                        
                        NSLog(@"Reponse : %@", responseObject);
                        NSLog(@"Prekey fetched :) ");
                        
                        
                        // Extracting the recipients keying material from server payload
                        
                        NSArray *keys = [responseObject objectForKey:@"keys"];
                        
                        for (NSDictionary *responseObject in keys){
                            NSData* theirIdentityKey = [NSData dataFromBase64String:[responseObject objectForKey:@"identityKey"]];
                            NSData* theirEphemeralKey = [NSData dataFromBase64String:[responseObject objectForKey:@"publicKey"]];
                            NSNumber* theirPrekeyId = [responseObject objectForKey:@"keyId"];
                            [recipient.deviceIDs addObject:[responseObject objectForKey:@"deviceId"]];
                            [TSMessagesDatabase storeContact:recipient];
                            
                            // remove the leading "0x05" byte as per protocol specs
                            if (theirEphemeralKey.length == 33) {
                                theirEphemeralKey = [theirEphemeralKey removeVersionByte];
                            }
                            
                            // remove the leading "0x05" byte as per protocol specs
                            if (theirIdentityKey.length == 33) {
                                theirIdentityKey = [theirIdentityKey removeVersionByte];
                            }
                            
                            // Bootstrap session with Prekey
                            TSSession *session = [[TSSession alloc] initWithContact:recipient deviceId:[[responseObject objectForKey:@"deviceId"] intValue]];
                            session.fetchedPrekey = [[TSPrekey alloc] initWithIdentityKey:theirIdentityKey  ephemeral:theirEphemeralKey prekeyId:[theirPrekeyId intValue]];
                            
                            [[TSMessagesManager sharedManager] submitMessage:message to:message.recipientId serializedMessage:[[[TSAxolotlRatchet encryptMessage:message withSession:session] getTextSecureProtocolData] base64EncodedString] ofType:TSPreKeyWhisperMessageType];
                        }
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
                NSLog(@"Error %@", error);
            }];
            
            
        }
        
    });
}

- (void)receiveMessagePush:(NSDictionary *)pushInfo{
    
    NSData *decryptedPayload = [Cryptography decryptAppleMessagePayload:[NSData dataFromBase64String:[pushInfo objectForKey:@"m"]] withSignalingKey:[TSKeyManager getSignalingKeyToken]];
    
    TSMessageSignal *signal = [[TSMessageSignal alloc] initWithTextSecureProtocolData:decryptedPayload];
    
    TSSession *session = [TSMessagesDatabase sessionForRegisteredId:signal.source deviceId:[signal.sourceDevice intValue]];
    
    TSMessage *decryptedMessage = [TSAxolotlRatchet decryptWhisperMessage:signal.message withSession:session];
    
    [TSMessagesDatabase storeMessage:decryptedMessage];
    
    // We probably want to submit an update to a subscribing view controller here.
}

-(void) submitMessage:(TSMessageOutgoing*)message to:(NSString*)recipientId serializedMessage:(NSString*)serializedMessage ofType:(TSWhisperMessageType)messageType{
#warning remove debug description
    if(messageType == TSEncryptedWhisperMessageType) {
        NSLog(@"submitting encrypted message: %@",[[[TSEncryptedWhisperMessage alloc] initWithTextSecureProtocolData:[NSData dataFromBase64String:serializedMessage]] debugDescription]);
    }
    else if (messageType == TSPreKeyWhisperMessageType){
        NSLog(@"submitting prekey message: %@",[[[TSPreKeyWhisperMessage alloc] initWithTextSecureProtocolData:[NSData dataFromBase64String:serializedMessage]] debugDescription]);

    }
    
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSSubmitMessageRequest alloc] initWithRecipient:recipientId message:serializedMessage ofType:messageType] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        switch (operation.response.statusCode) {
            case 200:{
                // Awesome! We consider the message as sent! (Improvement: add flag in DB for sent)
                
                NSLog(@"Message sent!");
                [message setState:TSMessageStateSent withCompletion:^(BOOL success) {
                    // Proceed to UI refresh;
                }];
                
                
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
        DLog(@"failure %ld, %@, %@",(long)operation.response.statusCode,operation.response.description,[[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TSDBDidUpdate" object:nil userInfo:@{@"messageType":@"send"}];
        
    }];
    
}


@end
