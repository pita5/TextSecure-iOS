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
NSString* const textSecureServer = @"http://gcm.textsecure.whispersystems.org";
#else
NSString* const textSecureServer = @"https://gcm.textsecure.whispersystems.org";
#endif


NSString* const textSecureAccountsAPI = @"v1/accounts";
NSString* const textSecureMessagesAPI = @"v1/messages";
NSString* const textSecureDirectoryAPI= @"v1/directory";
