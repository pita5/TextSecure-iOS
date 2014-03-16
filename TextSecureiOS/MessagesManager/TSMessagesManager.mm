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
#import "TSContact.h"
#import "TSPreKeyWhisperMessage.hh"
#import "TSRecipientPrekeyRequest.h"
#import "TSSession.h"

@interface TSMessagesManager (){
    dispatch_queue_t queue;
}
@end

@implementation TSMessagesManager

- (void)scheduleMessageSend:(TSMessage *)message
{
    [TSMessagesDatabase storeMessage:message];
#warning not implemented
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

-(void)sendMessage:(TSMessage*)message{
    dispatch_async(queue, ^{
        [TSMessagesDatabase storeMessage:message];
        
        
        TSContact *recipient = [TSMessagesDatabase contactForRegisteredID:message.recipientId];
        NSArray *sessions = [TSMessagesDatabase sessionsForContact:recipient];
        
        if ([sessions count] > 0) {
            for (TSSession *session in sessions){
                [[TSMessagesManager sharedManager] submitMessageTo:message.recipientId message:[[[TSAxolotlRatchet encryptMessage:message withSession:session] getTextSecure_WhisperMessage ]base64EncodedString] ofType:TSEncryptedWhisperMessageType];
            }
            
        } else{
            
            [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRecipientPrekeyRequest alloc] initWithRecipient:recipient] success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
                        
#warning Bootstrap session with prekey
                        // Bootstrap session with Prekey
                        TSSession *session;
                        
                        [[TSMessagesManager sharedManager] submitMessageTo:message.recipientId message:[[[TSAxolotlRatchet encryptMessage:message withSession:session] getTextSecure_WhisperMessage ]base64EncodedString] ofType:TSPreKeyWhisperMessageType];
                        
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
            
            
        }
        
    });
}

- (void)receiveMessagePush:(NSDictionary *)pushInfo{
    
#warning verify if database is open, if not, save somewhere else before processing.
    
#warning session needs to be decoded
    TSSession *session;
    
    TSEncryptedWhisperMessage *message = [[TSEncryptedWhisperMessage alloc] initWithTextSecure_WhisperMessage:[NSData  dataFromBase64String:[pushInfo objectForKey:@"m"]]];
    
    TSMessage *decryptedMessage = [TSAxolotlRatchet decryptMessage:message withSession:session];
    
    [TSMessagesDatabase storeMessage:decryptedMessage];
    
    
    // We probably want to submit an update to a subscribing view controller here.
}

-(void) submitMessageTo:(NSString*)recipientId message:(NSString*)serializedMessage ofType:(TSWhisperMessageType)messageType{
    
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
        DLog(@"failure %ld, %@, %@",(long)operation.response.statusCode,operation.response.description,[[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TSDBDidUpdate" object:nil userInfo:@{@"messageType":@"send"}];
        
    }];
    
}


@end
