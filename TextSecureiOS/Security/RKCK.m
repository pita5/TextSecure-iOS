//
//  RKCK.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/15/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "RKCK.h"
#import "TSECKeyPair.h"
#import "TSThread.h"
#import "TSHKDF.h"
#import "TSMessagesDatabase.h"

@implementation MKCK

+(id) withData:(NSData*)data {
  
  MKCK* mkck = [[MKCK alloc] init];
  
  
  mkck.MK =  [data subdataWithRange:NSMakeRange(0, 20)];
  mkck.CK = [data subdataWithRange:NSMakeRange(20, 20)];
  
  return mkck;
}


@end


@implementation RKCK
+(id) withData:(NSData*)data {
  
  RKCK* rkck = [[RKCK alloc] init];
  

 rkck.RK =  [data subdataWithRange:NSMakeRange(0, 20)];
 rkck.CK = [data subdataWithRange:NSMakeRange(20, 20)];
  
  return rkck;
}



-(RKCK*) createChainWithNewEphemeral:(TSECKeyPair*)myEphemeral fromTheirProvideEphemeral:(NSData*)theirPublicEphemeral {
  NSData* inputKeyMaterial = [myEphemeral generateSharedSecretFromPublicKey:theirPublicEphemeral];
  return [RKCK withData:[TSHKDF deriveKeyFromMaterial:inputKeyMaterial outputLength:64 info:[@"WhisperRatchet" dataUsingEncoding:NSASCIIStringEncoding] salt:self.RK]];
}


-(void) saveReceivingChainOnThread:(TSThread*)thread withTheirEphemeral:(NSData*)ephemeral {
  [TSMessagesDatabase setEphemeralOfReceivingChain:ephemeral onThread:thread];
  [TSMessagesDatabase setRK:self.RK onThread:thread];
  [TSMessagesDatabase setCK:self.CK onThread:thread onChain:TSReceivingChain];
  [TSMessagesDatabase setN:[NSNumber numberWithInt:0] onThread:thread onChain:TSReceivingChain];
}

-(void) saveSendingChainOnThread:(TSThread*)thread withMyNewEphemeral:(TSECKeyPair*)ephemeral {
  [TSMessagesDatabase setEphemeralOfSendingChain:ephemeral onThread:thread];
  [TSMessagesDatabase setRK:self.RK onThread:thread];
  [TSMessagesDatabase setCK:self.CK onThread:thread onChain:TSSendingChain];
  [TSMessagesDatabase setPNs:[TSMessagesDatabase getN:thread onChain:TSSendingChain] onThread:thread];
  [TSMessagesDatabase setN:[NSNumber numberWithInt:0] onThread:thread onChain:TSSendingChain];
}

+(RKCK*) currentSendingChain:(TSThread*)thread {
  RKCK* sendingChain = [[RKCK alloc] init];
  sendingChain.RK = [TSMessagesDatabase getRK:thread];
  sendingChain.CK = [TSMessagesDatabase getCK:thread onChain:TSSendingChain];
  sendingChain.ephemeral = [TSMessagesDatabase getEphemeralOfSendingChain:thread];
  return sendingChain;
}
@end
