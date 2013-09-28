//
//  TSNetworkManager.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSNetworkManager.h"
#import "TSRequest.h"

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
        operationQueue = [[NSOperationQueue alloc] init];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        textSecureSecureHTTPSManager = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:textSecureServer] sessionConfiguration:config];
        
        //textSecureSecureHTTPSManager
    }
    return self;
}

#pragma mark Manager Methods

- (void) addRequestToQueue:(TSRequest*) request success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)) successCompletionBlock failure: (void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)) failureCompletionBlock{
    
    NSURLSessionDataTask *dataTask = [textSecureSecureHTTPSManager GET:@"/hello" parameters:Nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
    
    [dataTask resume];
    
    AFHTTPRequestOperation *operation = textSecureSecureHTTPSManager ;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Print the response body in text
        NSLog(@"Response: %@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    [operationQueue addOperation:operation];
}


@end
