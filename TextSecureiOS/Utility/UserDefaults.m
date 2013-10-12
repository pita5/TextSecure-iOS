//
//  UserDefaults.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "UserDefaults.h"
#import "KeychainWrapper.h"
#import "Cryptography.h"

@implementation UserDefaults

// Detecting if a user has a verified phone number or not can be done by looking if a phone number is stored or not.
// If a phone number is present and no basic auth key, this means that a text message with a verification code has been sent but that the user never entered it.
// If both numbers are present, we are ready to use the app.

+(void) resetAllUserDefaults{
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:signalingTokenStorageId];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:usernameTokenStorageId];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:authenticationTokenStorageId];
}

+(BOOL) hasVerifiedPhoneNumber{
    return ([Cryptography getUsernameToken] && [Cryptography getAuthenticationToken]);
}


@end
