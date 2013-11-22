//
//  AppDelegate.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "AppDelegate.h"
#import "Cryptography.h"
#import "UserDefaults.h"
#import <PonyDebugger/PonyDebugger.h> //ponyd serve --listen-interface=127.0.0.1
#import "NSObject+SBJson.h"
#import "Message.h"
#import "EncryptedDatabase.h"
#import "TSRegisterForPushRequest.h"
#import "ECKeyPair.h"
#import "NSString+Conversion.h"
@implementation AppDelegate

#pragma mark - UIApplication delegate methods

#define firstLaunchKey @"FirstLaunch"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // If this is the first launch, we want to remove stuff from the Keychain that might be there from a previous install
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:firstLaunchKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:firstLaunchKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [UserDefaults removeAllKeychainItems];
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
	if([UserDefaults hasVerifiedPhoneNumber] && [EncryptedDatabase dataBaseWasInitialized]) {
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
		 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
     UIAlertView *passwordDialogue =   [[UIAlertView alloc] initWithTitle:@"Password" message:@"enter your password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    passwordDialogue.alertViewStyle = UIAlertViewStyleSecureTextInput;

    [passwordDialogue show];
    
	}
	return YES;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
#warning we will want better error handling, including reprompting if user enters password wrong
  if(buttonIndex==1) {
    NSString* password = [[alertView textFieldAtIndex:0] text];
      [EncryptedDatabase databaseUnlockWithPassword:password error:nil];
  }
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

    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"TextSecure needs push notifications" message:@"We couldn't enable push notifications. TexSecure uses them heavily. Please try registering again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
#ifdef DEBUG
#warning registering with dummy ID so that we can proceed in the simulator. You'll want to change this!
  [self application:application didRegisterForRemoteNotificationsWithDeviceToken:[[NSData alloc] initWithBase64Encoding:[@"christine" base64Encoded]]];
#endif
  
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	// TODO: add new message here!
	[self handlePush:userInfo];
}

-(void) handlePush:(NSDictionary *)pushInfo {
	NSDictionary* fullMessageJson = [[pushInfo objectForKey:@"message_body"] JSONValue];
	NSLog(@"full message json %@",fullMessageJson);
	Message *message = [[Message alloc] initWithText:[fullMessageJson objectForKey:@"messageText"] messageSource:[fullMessageJson objectForKey:@"source"] messageDestinations:[fullMessageJson objectForKey:@"destinations"] messageAttachments:[fullMessageJson objectForKey:@"attachments"] messageTimestamp:[NSDate date]];
#warning we need to handle this push!

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
