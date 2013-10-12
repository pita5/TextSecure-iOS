//
//  UserDefaults.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "UserDefaults.h"
#import <SSKeychain/SSKeychain.h>

@implementation UserDefaults

// Detecting if a user has a verified phone number or not can be done by looking if a phone number is stored or not.
// If a phone number is present and no basic auth key, this means that a text message with a verification code has been sent but that the user never entered it.
// If both numbers are present, we are ready to use the app.

#define kPhoneNumberKey @"TextSecurePhoneNumber"
#define kBasicAuthKey @"TextSecureAuthKey"
#define kServiceName @"Whisper"

+(void) resetAllUserDefaults{
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [SSKeychain deletePasswordForService:kServiceName account:kPhoneNumberKey];
}

+(BOOL) hasVerifiedPhoneNumber{
    return ([self phoneNumber] && [self basicAuthKey]);
}

#pragma mark Phone number - It's used in TextSecure as the username for the Basic Authentication.

+(NSString*)phoneNumber{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kPhoneNumberKey];
}

+(void)setPhoneNumber:(NSString*)phoneNumber{
    [[NSUserDefaults standardUserDefaults] setObject:phoneNumber forKey:kPhoneNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Basic Auth Key - Used for communication with the TextSecure Server

+(NSString*)basicAuthKey{
    return [SSKeychain passwordForService:kServiceName account:kBasicAuthKey];
}

+(void)setBasicAuthKey:(NSString*)password{
    [SSKeychain setPassword:password forService:kServiceName account:kBasicAuthKey];
}

@end
