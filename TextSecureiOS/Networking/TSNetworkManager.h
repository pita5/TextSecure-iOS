//
//  TSNetworkManager.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface TSNetworkManager : NSObject{
    NSOperationQueue *operationQueue;
    AFHTTPSessionManager *textSecureSecureHTTPSManager;
}

+ (id)sharedManager;

@end
