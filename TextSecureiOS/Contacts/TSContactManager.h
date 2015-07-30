//
//  TSContactManager.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSContact.h"

@interface TSContactManager : NSObject

+ (id)sharedManager;
+ (NSString*) cleanPhoneNumber:(NSString*)number;
+ (void) getAllContactsIDs:(void (^)(NSArray *contacts))contactFetchCompletionBlock;
- (NSNumber*) getContactIDForNumber:(NSString*) phoneNumber;

@end
