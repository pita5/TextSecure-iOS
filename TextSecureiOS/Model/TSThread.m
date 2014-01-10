//
//  TSThread.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSThread.h"
#import "TSParticipants.h"
#import "TSMessage.h"
#import "TSSendEphemerals.h"
#import "TSReceiveEphemerals.h"
#import "TSContact.h"
@implementation TSThread

+ (TSThread*) threadWithParticipants:(TSParticipants*)participants{
    TSThread *thread = [[TSThread alloc] init];
    thread.participants = participants;
    thread.threadID = [participants threadID];
    return thread;
}

+ (TSThread*) threadWithMeAndParticipantsByRegisteredIds:(NSArray*)participantRegisteredIds{
  NSMutableArray* others = [[NSMutableArray alloc] init];
  for(NSString* regid in participantRegisteredIds) {
    [others addObject:[[TSContact alloc] initWithRegisteredID:regid]];
  }
 [others addObject:[[TSContact alloc] initWithRegisteredID:[TSKeyManager getUsernameToken]]];

  return [TSThread threadWithParticipants:[[TSParticipants alloc] initWithTSContactsArray:others]];
}
@end
