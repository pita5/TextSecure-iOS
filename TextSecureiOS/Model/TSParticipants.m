//
//  TSParticipants.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSParticipants.h"
#import "TSContact.h"
#import "Cryptography.h"

@implementation TSParticipants

- (id) initWithTSContactsArray:(NSArray*)tsContacts{
    self = [super init];
    self.participants = tsContacts;
    return self;
}

- (NSString*) threadID{

  return [TSParticipants threadIDForParticipants:self.participants];
}

+ (NSString*) threadIDForParticipants:(NSArray*)tsContacts {
  NSString *phoneNumbers = [TSParticipants concatenatedPhoneNumbersForPaticipants:tsContacts];
  NSString* threadID= [Cryptography computeSHA1DigestForString:phoneNumbers];
  return threadID;



}

+ (NSString*) concatenatedPhoneNumbersForPaticipants:(NSArray*)tsContacts{
    NSMutableArray *phoneNumbers = [NSMutableArray array];
    for (TSContact *contact in tsContacts) {
        [phoneNumbers addObject:contact.registeredID];
    }

    NSArray *sortedArray = [phoneNumbers sortedArrayUsingDescriptors:
                            @[[NSSortDescriptor sortDescriptorWithKey:@"doubleValue"
                                                            ascending:YES]]];
  
  return [sortedArray componentsJoinedByString:@""];;
}

@end
