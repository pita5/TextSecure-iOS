//
//  TSServerCodeVerificationRequest.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSServerCodeVerificationRequest.h"
#import "Cryptography.h"
#import "NSString+Conversion.h"

@implementation TSServerCodeVerificationRequest

- (TSRequest*) initWithVerificationCode:(NSString*)verificationCode signalingKey:(NSString*)signalingKey authToken:(NSString*)authToken{
    self = [super initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@", textSecureAccountsAPI, @"code", verificationCode]]];
    
    [self.parameters addEntriesFromDictionary:[[NSDictionary alloc] initWithObjects:
                       [[NSArray alloc] initWithObjects:signalingKey, authToken, nil]
                            forKeys:[[NSArray alloc] initWithObjects:@"signalingKey", @"AuthKey", nil]]];
    
    [self setHTTPMethod:@"PUT"];
    
    return self;
}



@end
