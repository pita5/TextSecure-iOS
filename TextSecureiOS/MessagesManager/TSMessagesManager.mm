//
//  MessagesManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 30/11/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesManager.h"
#import "IncomingPushMessageSignal.hh"
#import "TSContact.h"
#import "NSData+Base64.h"
#import "TSSubmitMessageRequest.h"
#import "TSMessagesManager.h"
#import "TSKeyManager.h"
#import "Cryptography.h"
#import "TSMessage.h"
#import "TSMessagesDatabase.h"


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

- (void)processPushNotification:(NSDictionary *)pushInfo{
  // obviously
  NSData *payload = [NSData dataFromBase64String:[pushInfo objectForKey:@"m"]];
  unsigned char version[1];
  unsigned char iv[16];
  int ciphertext_length=([payload length]-10-17)*sizeof(char);
  unsigned char *ciphertext =  (unsigned char*)malloc(ciphertext_length);
  unsigned char mac[10];
  [payload getBytes:version range:NSMakeRange(0, 1)];
  [payload getBytes:iv range:NSMakeRange(1, 16)];
  [payload getBytes:ciphertext range:NSMakeRange(17, [payload length]-10-17)];
  [payload getBytes:mac range:NSMakeRange([payload length]-10, 10)];
  
  
  NSData* signalingKey = [NSData dataFromBase64String:[TSKeyManager getSignalingKeyToken]];
  // Actually only the first 32 bits of this are the crypto key
  NSData* signalingKeyAESKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(0, 32)];
  NSData* signalingKeyHMACKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(32, 20)];
  NSData* decryption=[Cryptography decryptPushPayload:[NSData dataWithBytes:ciphertext length:ciphertext_length] withKey:signalingKeyAESKeyMaterial withIV:[NSData dataWithBytes:iv length:16] withVersion:[NSData dataWithBytes:version length:1] withHMACKey:signalingKeyHMACKeyMaterial forHMAC:[NSData dataWithBytes:mac length:10]];
  NSLog(@"length of decryption %d",[decryption length]);
  // Now get the protocol buffer message out
  textsecure::IncomingPushMessageSignal *fullMessageInfoRecieved = [IncomingPushMessageSignal getIncomingPushMessageSignalForData:decryption];
  
  NSString *decryptedMessage = [IncomingPushMessageSignal getMessageBody:fullMessageInfoRecieved];
  NSString *decryptedMessageAndInfo = [IncomingPushMessageSignal prettyPrint:fullMessageInfoRecieved];
  [TSMessagesDatabase storeMessage:[IncomingPushMessageSignal getTSMessage:fullMessageInfoRecieved]];
  
  UIAlertView *pushAlert = [[UIAlertView alloc] initWithTitle:@"you have a new message" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:TSDatabaseDidUpdateNotification object:self];
  [pushAlert show];

}


-(void) sendMessage:(TSMessage*)message {

  NSString *serializedMessage = [[IncomingPushMessageSignal createSerializedPushMessageContent:message.message withAttachments:nil] base64Encoding];
  //Tests deserialization
  //NSString* deserializedMessage = [IncomingPushMessageSignal prettyPrintPushMessageContent:[IncomingPushMessageSignal getPushMessageContentForData:[NSData dataFromBase64String:serializedMessage]]];
  [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSSubmitMessageRequest alloc] initWithRecipient:message.recipientId message:serializedMessage] success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
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
#warning Add error handling if not able to send the token
    DLog(@"failure %d, %@, %@",operation.response.statusCode,operation.response.description,[[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);
    
    
  }];
  
  
}

@end
