//
//  Constants.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "Constants.h"

NSString* const appName = @"TextSecure";
NSString* const authenticationTokenStorageId = @"TextSecureAuthenticationToken";
NSString* const usernameTokenStorageId = @"UsernameAuthenticationToken";
NSString* const signalingTokenStorageId = @"SignalingTokenStorageId";
<<<<<<< HEAD
NSString* const prekeyCounterStorageId = @"PrekeyCounterStorageId";
NSString* const textSecureServer = @"https://gcm.textsecure.whispersystems.org";
=======
NSString* const textSecureServer = @"https://gcm.textsecure.whispersystems.org/";
>>>>>>> 223addd911b7d6a13c35b2e5272068e3b2bfa415


// timeout in seconds
double const timeOutForRequests = 15;

NSString* const textSecureAccountsAPI = @"v1/accounts";
NSString* const textSecureMessagesAPI = @"v1/messages";
NSString* const textSecureKeysAPI = @"v1/keys";
NSString* const textSecureDirectoryAPI= @"v1/directory";
