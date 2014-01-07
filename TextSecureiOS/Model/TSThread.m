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
@implementation TSThread

+ (TSThread*) threadWithParticipants:(TSParticipants*)participants{
    TSThread *thread = [[TSThread alloc] init];
    thread.participants = participants;
    thread.threadID = [participants threadID];
    thread.sendEphemerals = [[TSSendEphemerals alloc] init];
    thread.receiveEphemerals = [[TSReceiveEphemerals alloc] init];
    return thread;
}

@end
