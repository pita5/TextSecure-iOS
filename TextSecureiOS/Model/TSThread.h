//
//  TSThread.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocols.h"
@class TSParticipants;
@class TSMessage;
@interface TSThread : NSObject

@property (nonatomic, copy) NSString *threadID;
@property (nonatomic, retain) TSParticipants *participants;
@property (nonatomic, retain) TSMessage *latestMessage;

+ (TSThread*) threadWithParticipants:(TSParticipants*)participants;

+ (TSThread*) threadWithMeAndParticipantsByRegisteredIds:(NSArray*)participantRegisteredIds;
@end
