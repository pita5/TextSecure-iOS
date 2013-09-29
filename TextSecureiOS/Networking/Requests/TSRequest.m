//
//  TSRequest.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRequest.h"
#import "Cryptography.h"

@implementation TSRequest

- (id)initWithURL:(NSURL *)URL{
    self = [super initWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:timeOutForRequests];

    return self;
}

- (id)init{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must use the initWithURL: method"];
    return nil;
}

- (id)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval{
    [NSException raise:NSInternalInconsistencyException
                format:@"You must use the initWithURL method"];
    return nil;
}

- (void) addHTTPHeaders {
    self.parameters = @{@"Content-Type": @"application/json",
             @"Authorization": [NSString stringWithFormat:@"Basic %@",[Cryptography getAuthorizationToken]],
             @"Content-Length":[NSString stringWithFormat:@"%d", [self.HTTPBody length]]};
}


@end
