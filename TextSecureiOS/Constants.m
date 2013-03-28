//
//  Constants.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "Constants.h"


#define TEST

NSString* const appName = @"TextSecure";
NSString* const authenticationTokenStorageId = @"TextSecureAuthenticationToken";
NSString* const usernameTokenStorageId = @"UsernameAuthenticationToken";
#ifdef TEST
NSString* const textSecureServer = @"https://textsecure-gcm-test.herokuapp.com";
#endif
NSString* const textSecureAccountsAPI = @"v1/accounts";
