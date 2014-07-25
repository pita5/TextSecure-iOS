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
NSString* const prekeyCounterStorageId = @"PrekeyCounterStorageId";
NSString* const encryptedMasterSecretKeyStorageId  = @"EncryptedMasterSecretKeyStorageId";

NSString* const textSecureWebSocketAPI = @"wss://textsecure-service-staging.whispersystems.org/v1/websocket/";
NSString* const textSecureServer = @"https://textsecure-service-staging.whispersystems.org/";

NSString* const textSecureGeneralAPI = @"v1";
NSString* const textSecureAccountsAPI = @"v1/accounts";
NSString* const textSecureMessagesAPI = @"v1/messages/"; // NOTE trailing slash is important
NSString* const textSecureKeysAPI = @"v1/keys";
NSString* const textSecureDirectoryAPI= @"v1/directory";
NSString* const textSecureAttachmentsAPI= @"v1/attachments";

NSTimeInterval const timeOutForRequests = 10;
unsigned char  const textSecureVersion = 0;

// CountryCodes.plist constants
NSString* const countryInfoPathInMainBundle = @"CountryCodes";
NSString* const countryInfoKeyCountryCode = @"country_code";
NSString* const countryInfoKeyName = @"name";
