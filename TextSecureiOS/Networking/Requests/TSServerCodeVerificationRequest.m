//
//  TSServerCodeVerificationRequest.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSServerCodeVerificationRequest.h"
#import "Cryptography.h"

@implementation TSServerCodeVerificationRequest

- (TSRequest*) initWithVerificationCode:(NSString*)verificationCode signalingKey:(NSString*)signalingKey authToken:(NSString*)authToken{
    self = [super initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@", textSecureAccountsAPI, @"code", [Cryptography getUsernameToken]]]];
    
    self.parameters = [[NSDictionary alloc] initWithObjects:
                       [[NSArray alloc] initWithObjects:signalingKey, [Cryptography getAuthorizationTokenFromAuthToken:authToken], nil]
                            forKeys:[[NSArray alloc] initWithObjects:@"signalingKey", @"Authorization", nil]];
    
    [self setHTTPMethod:@"PUT"];
    
    [self setHTTPBody:[NSData dataWithData:nil]];
    
    return self;
}



@end
