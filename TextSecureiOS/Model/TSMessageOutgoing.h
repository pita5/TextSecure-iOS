//
//  TSMessageOutgoing.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSMessage.h"

typedef enum {
    TSMessageStateDraft,
    TSMessageStatePendingSend,
    TSMessageStateSent
} TSMessageOutgoingState;

@interface TSMessageOutgoing : TSMessage

@property (readonly) TSMessageOutgoingState messageState;

-(instancetype) initWithMessageWithContent:(NSString *)text recipient:(NSString *)recipientId date:(NSDate*)timestamp attachements:(NSArray*)attachements group:(TSGroup*)group state:(TSMessageOutgoingState)state;

- (void)setState:(TSMessageOutgoingState)state withCompletion:(TSMessageChangeState)block;

@end
