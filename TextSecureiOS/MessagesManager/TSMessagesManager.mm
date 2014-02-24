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
        
    }
    return self;
}

- (void)receiveMessagePush:(NSDictionary *)pushInfo{
    [TSAxolotlRatchet receiveMessage:[NSData  dataFromBase64String:[pushInfo objectForKey:@"m"]]];
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
