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
    }
    return self;
}

#pragma mark Manager Methods

- (void) queueAuthenticatedRequest:(TSRequest*) request success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))successCompletionBlock failure: (void (^)(AFHTTPRequestOperation *operation, NSError *error)) failureCompletionBlock{
    
    if ([request.HTTPMethod isEqualToString:@"GET"]) {
        NSLog(@"GET API Endpoint : %@", request.URL.absoluteString);
        [operationManager GET:request.URL.absoluteString parameters:request.parameters success:successCompletionBlock failure:failureCompletionBlock];
    } else if ([request.HTTPMethod isEqualToString:@"POST"]){
        NSLog(@"POST API Endpoint : %@ with params : %@", request.URL.absoluteString, request.parameters);
        [operationManager POST:request.URL.absoluteString parameters:request.parameters success:successCompletionBlock failure:failureCompletionBlock];
    }
    
}


@end
