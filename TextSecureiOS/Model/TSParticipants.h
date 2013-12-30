//
//  TSParticipants.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSParticipants : NSMutableArray

- (id) initWithTSContactsArray:(NSArray*)tsContacts;

- (NSString*) threadID;
+ (NSString*) concatenatedPhoneNumbersForPaticipants:(NSArray*)tsContacts;
+ (NSString*) threadIDForParticipants:(NSArray*)tsContacts;
@end
