//
//  AppDelegate.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "AppDelegate.h"
#import "Cryptography.h"
#import "TSKeyManager.h"
#import <PonyDebugger/PonyDebugger.h> //ponyd serve --listen-interface=127.0.0.1
#import "NSObject+SBJson.h"
#import "TSMessagesDatabase.h"
#import "TSStorageMasterKey.h"
#import "TSStorageError.h"
#import "TSRegisterForPushRequest.h"
#import "NSString+Conversion.h"
#import "TSMessagesManager.h"
#import "NSData+Base64.h"

@implementation AppDelegate

#pragma mark - UIApplication delegate methods

#define firstLaunchKey @"FirstLaunch"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // UIAppearance proxy setup
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:33/255. green:127/255. blue:248/255. alpha:1]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor grayColor]} forState:UIControlStateDisabled];
    
    
    // If this is the first launch, we want to remove stuff from the Keychain that might be there from a previous install
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:firstLaunchKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:firstLaunchKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [TSKeyManager removeAllKeychainItems];
        DLog(@"First Launch");
      
    }
    
#ifdef DEBUG
	[[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:@"9e6b7f4732558ba8480fb2bcd0a5c3da"
														 liveIdentifier:@"9e6b7f4732558ba8480fb2bcd0a5c3da"
															   delegate:self];
	[[BITHockeyManager sharedHockeyManager] startManager];
    
    PDDebugger *debugger = [PDDebugger defaultInstance];
    [debugger connectToURL:[NSURL URLWithString:@"ws://localhost:9000/device"]];
    [debugger enableNetworkTrafficDebugging];
    [debugger forwardAllNetworkTraffic];
#endif
	
	if(launchOptions!=nil) {
		[self handlePush:launchOptions];
	}
	if([TSKeyManager hasVerifiedPhoneNumber] && [TSMessagesDatabase databaseWasCreated]) {
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
		 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	}
	return YES;

}

#pragma mark - Push notifications

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
	NSString *stringToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	stringToken = [stringToken stringByReplacingOccurrencesOfString:@" " withString:@""];
	
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRegisterForPushRequest alloc] initWithPushIdentifier:stringToken] success:^(AFHTTPRequestOperation *operation, id responseObject) {

        switch (operation.response.statusCode) {
            case 200:
                DLog(@"Device registered for push notifications");
                break;
                
            default:
#warning Add error handling if not able to send the token
                break;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
    }];
    
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {

    
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TextSecure needs push notifications" message:@"We couldn't enable push notifications. TexSecure uses them heavily. Please try registering again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
//    [alert show];
    
#ifdef DEBUG
#warning registering with dummy ID so that we can proceed in the simulator. You'll want to change this!
  NSData *deviceToken = [NSData dataFromBase64String:[@"christine" base64Encoded]];
  [self application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
#endif
  
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	[self handlePush:userInfo];
}

-(void) handlePush:(NSDictionary *)pushInfo {
  [[TSMessagesManager sharedManager]receiveMessagePush:pushInfo];
}

#pragma mark - HockeyApp Delegate Methods

#ifdef DEBUG
- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager {
#ifndef CONFIGURATION_AppStore
	if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
		return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
#endif
	return nil;
}
#endif

@end
