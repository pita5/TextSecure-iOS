//
//  TSThread.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSThread.h"
#import "TSMessage.h"
#import "TSContact.h"
#import "Cryptography.h"


@implementation TSThread


#pragma mark Private methods
+ (NSString*) concatenatedPhoneNumbersForContacts:(NSArray*)tsContacts {
    
    // Extract the contacts' phone numbers
    NSMutableArray *phoneNumbers = [NSMutableArray array];
    for (TSContact *contact in tsContacts) {
        [phoneNumbers addObject:contact.registeredID];
    }
    
    // Sort the phone numbers so we always get the same hash for the same list of contacts
    NSArray *sortedArray = [phoneNumbers sortedArrayUsingDescriptors:
                            @[[NSSortDescriptor sortDescriptorWithKey:@"doubleValue"
                                                            ascending:YES]]];
    // Convert the result to a string
    return [sortedArray componentsJoinedByString:@""];
}


# pragma mark Thread creation method
+ (TSThread*) threadWithContacts:(NSArray*)participants {
    TSThread *thread = [[TSThread alloc] init];
    
    // Current user is always part of threads they have on their device
    NSMutableArray *allParticipants = [NSMutableArray arrayWithArray:participants];
    [allParticipants addObject:[[TSContact alloc] initWithRegisteredID:[TSKeyManager getUsernameToken]]];
    thread.participants = [NSArray arrayWithArray:allParticipants];
    
    // Generate the corresponding thread ID
    NSString *phoneNumbers = [TSThread concatenatedPhoneNumbersForContacts:participants];
    thread.threadID = [Cryptography computeSHA1DigestForString:phoneNumbers];
    
    return thread;
}


@end
