//
//  TSContactManager.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSContactManager : NSObject

+ (id)sharedManager;

+ (void) getAllContactsIDs:(void (^)(NSArray *contacts))contactFetchCompletionBlock;

@end
