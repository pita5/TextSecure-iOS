//
//  MessagesManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 30/11/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessagesManager.h"

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
  NSLog(@"full message json %@",pushInfo);
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
  
  
  NSData* signalingKey = [NSData dataFromBase64String:[Cryptography getSignalingKeyToken]];
  NSLog(@"signaling key %@",[Cryptography getSignalingKeyToken]);
  // Actually only the first 32 bits of this are the crypto key
  NSData* signalingKeyAESKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(0, 32)];
  NSData* signalingKeyHMACKeyMaterial = [signalingKey subdataWithRange:NSMakeRange(32, 20)];
  NSData* decryption=[Cryptography CC_AES256_CBC_Decryption:[NSData dataWithBytes:ciphertext length:ciphertext_length] withKey:signalingKeyAESKeyMaterial withIV:[NSData dataWithBytes:iv length:16] withVersion:[NSData dataWithBytes:version length:1] withMacKey:signalingKeyHMACKeyMaterial forMac:[NSData dataWithBytes:mac length:10]];
  
  // Now get the protocol buffer message out
  textsecure::IncomingPushMessageSignal *fullMessageInfoRecieved = [IncomingPushMessageSignal getIncomingPushMessageSignalForData:decryption];
  
  NSString *decryptedMessage = [IncomingPushMessageSignal getMessageBody:fullMessageInfoRecieved];
  NSString *decryptedMessageAndInfo = [IncomingPushMessageSignal prettyPrint:fullMessageInfoRecieved];
  UIAlertView *pushAlert = [[UIAlertView alloc] initWithTitle:@"decrypted message" message:decryptedMessageAndInfo delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
  [pushAlert show];
#warning we need to handle this push!, the UI will need to select the appropriate message view
}

- (void)dealloc {

}

@end
