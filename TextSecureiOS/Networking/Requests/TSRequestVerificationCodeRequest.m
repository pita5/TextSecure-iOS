//
//  TSSendSMSVerificationRequest.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRequestVerificationCodeRequest.h"

@implementation TSRequestVerificationCodeRequest

- (TSRequest*) initRequestForPhoneNumber:(NSString*)phoneNumber transport:(VerificationTransportType)transport{
    
    self = [super initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@", textSecureAccountsAPI, (transport == kSMSVerification)? @"sms" : @"voice", [phoneNumber escape]]]];
    
    [self setHTTPMethod:@"POST"];
    [self setHTTPBody:[NSData dataWithData:nil]];
    
    [self addHTTPHeaders];
    
    return self;
    
}

- (void) addHTTPHeaders{
    self.parameters = @{@"Content-Length": @0};
}


@end
