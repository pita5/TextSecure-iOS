//
//  TSNetworkManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSNetworkManager.h"
#import "TSRequest.h"
#import "Cryptography.h"

@implementation TSNetworkManager

#pragma mark Singleton implementation

+ (id)sharedManager {
    static TSNetworkManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        operationManager = [[AFHTTPRequestOperationManager manager] initWithBaseURL:[[NSURL alloc] initWithString:textSecureServer]];
        operationManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
    }
    return self;
}

#pragma mark Manager Methods

- (void) queueAuthenticatedRequest:(TSRequest*) request success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successCompletionBlock failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error)) failureCompletionBlock{
    
    DLog(@"%@", [textSecureServer stringByAppendingString:request.URL.absoluteString]);
    
    // The only unauthenticated request is the initial request for a verification code
    
    if ([request isKindOfClass:[TSRequestVerificationCodeRequest class]]) {
        [operationManager PUT:[textSecureServer stringByAppendingString:request.URL.absoluteString] parameters:request.parameters success:successCompletionBlock failure:failureCompletionBlock];
    } else{
        
        if ([request.HTTPMethod isEqualToString:@"GET"]) {
            [operationManager GET:[textSecureServer stringByAppendingString:request.URL.absoluteString] parameters:request.parameters success:successCompletionBlock failure:failureCompletionBlock];
        } else if ([request.HTTPMethod isEqualToString:@"POST"]){
            [operationManager POST:[textSecureServer stringByAppendingString:request.URL.absoluteString] parameters:request.parameters success:successCompletionBlock failure:failureCompletionBlock];
        } else if ([request.HTTPMethod isEqualToString:@"PUT"]){
            [operationManager PUT:[textSecureServer stringByAppendingString:request.URL.absoluteString] parameters:request.parameters success:successCompletionBlock failure:failureCompletionBlock];
        }
    }
}


@end
