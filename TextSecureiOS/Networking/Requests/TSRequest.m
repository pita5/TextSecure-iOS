//
//  TSRequest.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRequest.h"
#import "TSKeyManager.h"

@implementation TSRequest

- (id)initWithURL:(NSURL *)URL{
    self = [super initWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:timeOutForRequests];
    self.parameters = [NSMutableDictionary dictionary];
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

- (void) makeAuthenticatedRequest{
    [self.parameters addEntriesFromDictionary:@{@"Authorization":[TSKeyManager getAuthorizationToken]}];
}

- (BOOL) usingExternalServer {
  return NO;
}
@end
