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

@property (nonatomic, copy) NSString *threadID;         // A hash of all the participants' phone numbers
@property (nonatomic,strong) NSArray *participants;     // An array of TSContact objects
@property (nonatomic, retain) TSMessage *latestMessage;
//@property (nonatomic, retain) TSAxolotlThreadState *axolotlVariables;


+ (TSThread*) threadWithContacts:(NSArray*)participants;


@end
