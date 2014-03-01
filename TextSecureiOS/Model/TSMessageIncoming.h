//
//  TSMessageIncoming.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessage.h"

@interface TSMessageIncoming : TSMessage

typedef enum {
    TSMessageStateReceived,
    TSMessageStateRead
} TSMessageIncomingState;

- (instancetype) initWithMessageWithContent:(NSString *)text sender:(NSString *)sender date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageIncomingState)state;

- (void)setState:(TSMessageIncomingState)state withCompletion:(TSMessageChangeState)block;

@end