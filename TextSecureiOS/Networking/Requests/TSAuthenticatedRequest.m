//
//  TSAuthenticatedRequest.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSAuthenticatedRequest.h"
#import "Cryptography.h"

@implementation TSAuthenticatedRequest

- (id)initWithURL:(NSURL *)URL{
    self = [super initWithURL:URL];
    [self.parameters addEntriesFromDictionary:@{@"Authorization": [Cryptography getAuthorizationToken]}];
    return self;
}

@end
