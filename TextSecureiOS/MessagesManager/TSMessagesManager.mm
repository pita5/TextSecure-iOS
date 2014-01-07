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
#import "PushMessageContent.hh"
#import "TSThread.h"


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
  NSData* decryption=[Cryptography decrypt:[NSData dataWithBytes:ciphertext length:ciphertext_length] withKey:signalingKeyAESKeyMaterial withIV:[NSData dataWithBytes:iv length:16] withVersion:[NSData dataWithBytes:version length:1] withHMACKey:signalingKeyHMACKeyMaterial forHMAC:[NSData dataWithBytes:mac length:10]];
  // Now get the protocol buffer message out
  textsecure::IncomingPushMessageSignal *fullMessageInfoRecieved = [IncomingPushMessageSignal getIncomingPushMessageSignalForData:decryption];
  
  // This protocol buffer has a type which indicates whether its encrypted message is encapsulated in the PreKeyWhisperMessage format or the WhisperMessage format, it also has e.g. source, destination and timstame
  
  // sets [thread.receiveEphemerals setReceiveEphemerals];
  TSThread* thread = [IncomingPushMessageSignal getTSThreadForIncomingPushMessageSignal:fullMessageInfoRecieved];
  // This allocation will update the keys as needed
  TSWhisperMessage* whisperMessage = [IncomingPushMessageSignal getWhisperMessageIncomingPushMessageSignal:fullMessageInfoRecieved];
  NSData* encryptedPushMessageContent = [whisperMessage getEncryptedPushMessageContent];
  // All the ephemeral and persistant variables are updated, so we can go through the decryption process!
  TSMessage* message = [self decryptMessage:encryptedPushMessageContent onThread:thread];
  [TSMessagesDatabase storeMessage:message];
  UIAlertView *pushAlert = [[UIAlertView alloc] initWithTitle:@"you have a new message" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:TSDatabaseDidUpdateNotification object:self userInfo:@{@"messageType":@"receive"}];
  [pushAlert show];

}


#pragma mark TSProtocol
-(NSData*) encryptMessage:(TSMessage*)message onThread:(TSThread*)thread {
#warning not implemented
  return nil;
  
}
-(TSMessage*) decryptMessage:(NSData*)message onThread:(TSThread*)thread  {
#warning not implemented
  
  return nil;
  
}

-(void) sendMessage:(TSMessage*)message onThread:(TSThread*)thread {
  [TSMessagesDatabase storeMessage:message];
  [thread.sendEphemerals setSendEphemerals];
  NSString *serializedMessage = [[PushMessageContent createSerializedPushMessageContent:message.message withAttachments:nil] base64Encoding];
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
#warning right now it is not succesfully processing returned response, but is giving 200
    DLog(@"failure %d, %@, %@",operation.response.statusCode,operation.response.description,[[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding]);
    [[NSNotificationCenter defaultCenter] postNotificationName:TSDatabaseDidUpdateNotification object:self userInfo:@{@"messageType":@"send"}];
    
  }];
  
  
}


@end
