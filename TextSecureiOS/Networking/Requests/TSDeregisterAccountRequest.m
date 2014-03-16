//
//  TSDeregisterAccountRequest.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/16/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSDeregisterAccountRequest.h"

@implementation TSDeregisterAccountRequest


- (id)initWithUser:(NSString*)user {
    
    self = [super initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/code/%@", textSecureAccountsAPI, @"sms", user]]];

    
    self.HTTPMethod = @"DELETE";

    return self;
    
}
@end
