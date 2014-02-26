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

typedef void(^performSaveOnChainCompletionBlock) (BOOL success);
typedef void(^fetchCurrentSendingChainCompletionBlock) (RKCK* keypair);

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


-(void) saveReceivingChainOnThread:(TSThread*)thread withTheirEphemeral:(NSData*)ephemeral withCompletionHandler:(performSaveOnChainCompletionBlock)block{
    [TSMessagesDatabase setEphemeralOfReceivingChain:ephemeral onThread:thread withCompletionBlock:^(BOOL sucess) {
        [TSMessagesDatabase setRK:self.RK onThread:thread withCompletionBlock:^(BOOL success) {
            [TSMessagesDatabase setCK:self.CK onThread:thread onChain:TSReceivingChain withCompletionBlock:^(BOOL success) {
                [TSMessagesDatabase setN:[NSNumber numberWithInt:0] onThread:thread onChain:TSReceivingChain withCompletionBlock:^(BOOL success) {
                    if (success) {
                        block(YES);
                    }
                }];
            }];
        }];
    }];
}

-(void) saveSendingChainOnThread:(TSThread*)thread withMyNewEphemeral:(TSECKeyPair *)ephemeral withCompletionHandler:(performSaveOnChainCompletionBlock)block{
    [TSMessagesDatabase setEphemeralOfSendingChain:ephemeral onThread:thread withCompletionBlock:^(BOOL success) {
        [TSMessagesDatabase setRK:self.RK onThread:thread withCompletionBlock:^(BOOL success) {
            [TSMessagesDatabase setCK:self.CK onThread:thread onChain:TSSendingChain withCompletionBlock:^(BOOL success) {
                [TSMessagesDatabase getN:thread onChain:TSSendingChain withCompletionBlock:^(NSNumber *number) {
                    [TSMessagesDatabase setPNs:number onThread:thread withCompletionBlock:^(BOOL success) {
                        [TSMessagesDatabase setN:[NSNumber numberWithInt:0] onThread:thread onChain:TSSendingChain withCompletionBlock:^(BOOL success){
                            if (success) {
                                block(YES);
                            }
                        }];
                    }];
                }];
            }];
        }];
    }];
};


+(void) currentSendingChain:(TSThread*)thread withCompletionHandler:(fetchCurrentSendingChainCompletionBlock)block{
    RKCK* sendingChain = [[RKCK alloc] init];
    [TSMessagesDatabase getRK:thread withCompletionBlock:^(NSData* dataRK) {
        sendingChain.RK = dataRK;
        [TSMessagesDatabase getCK:thread onChain:TSSendingChain withCompletionBlock:^(NSData *dataCK) {
            sendingChain.CK = dataCK;
            [TSMessagesDatabase getEphemeralOfSendingChain:thread withCompletionBlock:^(TSECKeyPair* ephemeral) {
                sendingChain.ephemeral = ephemeral;
                block(sendingChain);
            }];
        }];
    }];
}
@end
