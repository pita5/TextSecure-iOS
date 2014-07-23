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

- (void)scheduleMessageSend:(TSMessageOutgoing *)message {
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





-(void)sendMessage:(TSMessageOutgoing*)message {
    if(message.group!=nil) {
        for(TSContact* recipient in [TSMessagesDatabase membersForGroup:message.group]) {
            if([recipient.registeredID isEqualToString:[TSKeyManager getUsernameToken]]){
                continue;
            }
            [self sendMessage:[message copyMessageToRecipient:recipient.registeredID] toContact:recipient];
        }
    }
    else {
        TSContact *recipient = [TSMessagesDatabase contactForRegisteredID:message.recipientId];
        [self sendMessage:message toContact:recipient];
    }
}


-(void)sendMessage:(TSMessageOutgoing*)message toContact:(TSContact*) recipient{
        dispatch_async(queue, ^{
            TSContact *recipientInDb = [TSMessagesDatabase contactForRegisteredID:recipient.registeredID]; // makes sure that we get the latest relay info, etc.

            NSArray *sessions = [TSMessagesDatabase sessionsForContact:recipientInDb];
            
            if ([sessions count] > 0) {
                for (TSSession *session in sessions){
                    [[TSMessagesManager sharedManager] submitMessage:message to:message.recipientId serializedMessage:[[[TSAxolotlRatchet encryptMessage:message withSession:session] getTextSecureProtocolData] base64EncodedString] ofType:TSEncryptedWhisperMessageType];
                }
                
            } else{
                
                [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRecipientPrekeyRequest alloc] initWithRecipient:recipient] success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    switch (operation.response.statusCode) {
                        case 200:{
                            

                            
                            // Extracting the recipients keying material from server payload
                            
                            NSArray *keys = [responseObject objectForKey:@"keys"];
                            
                            for (NSDictionary *responseObject in keys){
                                NSData* theirIdentityKey = [NSData dataFromBase64String:[responseObject objectForKey:@"identityKey"]];
                                
                                
                                if (recipient.identityKey && ![recipient.identityKey isEqualToData:theirIdentityKey]) {
                                    // this is a weird case, where we already have a stored ID key for a person, but don't have a session for that person.
    #warning we want to give user option to continue or not this will crash in the DB when the key is being stored, as we aren't allowed to do this in DB currently. at least user knows why with this message
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning!" message:@"The contact's identity key has changed from one you've previously received. This could either mean that someon is trying to intercept your communication or that this contact simply re-isntall TextSecure and now has a new identity key " delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                    [alert show];
                                }

                                NSData* theirEphemeralKey = [NSData dataFromBase64String:[responseObject objectForKey:@"publicKey"]];
                                NSNumber* theirPrekeyId = [responseObject objectForKey:@"keyId"];
                                [recipient.deviceIDs addObject:[responseObject objectForKey:@"deviceId"]];
                                recipient.identityKey = theirEphemeralKey;
                                [TSMessagesDatabase storeContact:recipient];
                                if(message.group==nil) {
                                    [[NSNotificationCenter defaultCenter] postNotificationName:recipient.registeredID object:self];
                                }
                                else {
                                    [[NSNotificationCenter defaultCenter] postNotificationName:[message.group.groupContext getEncodedId] object:self];
                                }

                                // Bootstrap session with Prekey
                                TSSession *session = [[TSSession alloc] initWithContact:recipient deviceId:[[responseObject objectForKey:@"deviceId"] intValue]];
                                session.pendingPreKey = [[TSPrekey alloc] initWithIdentityKey:[theirIdentityKey removeVersionByte]  ephemeral:[theirEphemeralKey removeVersionByte] prekeyId:[theirPrekeyId intValue]];
                                session.needsInitialization = YES;
                                
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
    NSLog(@"push message bytes %lu",(unsigned long) decryptedPayload.length);
    
    TSMessageSignal *signal = [[TSMessageSignal alloc] initWithTextSecureProtocolData:decryptedPayload];
    
    if (![TSMessagesDatabase contactForRegisteredID:signal.source]) {
        [[[TSContact alloc] initWithRegisteredID:signal.source relay:nil] save];
    }
    
    TSSession *session = [TSMessagesDatabase sessionForRegisteredId:signal.source deviceId:[signal.sourceDevice intValue]];
    
    TSMessage *decryptedMessage = [TSAxolotlRatchet decryptWhisperMessage:signal.message withSession:session];
    if(decryptedMessage.group!=nil) {
        NSLog(@"incoming group id is %@",[decryptedMessage.group.groupContext getEncodedId]);
    }
    [TSMessagesDatabase storeMessage:decryptedMessage];
}

-(void) submitMessage:(TSMessageOutgoing*)message to:(NSString*)recipientId serializedMessage:(NSString*)serializedMessage ofType:(TSWhisperMessageType)messageType{
    NSData* data=[serializedMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"submitting message of %lu bytes",(unsigned long)data.length);
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSSubmitMessageRequest alloc] initWithRecipient:recipientId message:serializedMessage ofType:messageType] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        switch (operation.response.statusCode) {
            case 200:{
                // Awesome! We consider the message as sent! (Improvement: add flag in DB for sent)
                NSLog(@"Message sent! %@", responseObject);
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
        [[NSNotificationCenter defaultCenter] postNotificationName:kDBNewMessageNotification object:nil userInfo:@{@"messageType":@"sent"}];
        
    }];
    
}


@end
