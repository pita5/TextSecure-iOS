//
//  TSThread.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSThread.h"

@implementation TSThread

+ (TSThread*) threadWithParticipants:(TSParticipants*)participants{
    TSThread *thread = [[TSThread alloc] init];
    thread.participants = participants;
    thread.threadID = [participants threadID];
    return thread;
}

@end
