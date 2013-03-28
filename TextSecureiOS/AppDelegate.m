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
@implementation AppDelegate
@synthesize server;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // notification details held in the launchOptions dictionary. if the dictionary is nil then the user tapped the application icon as normal.
    self.server = [[Server alloc] init];
  
    if([UserDefaults hasVerifiedPhone]) {
      [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
       (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markVerifiedPhone:) name:@"VerifiedPhone" object:nil];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markSentVerification:) name:@"SentVerification" object:nil];

    return YES;
}

-(void)  cryptoDemo {
  [Cryptography testEncryption];
  // demoing generating and storing account authentication token. Just for prototyping
  [Cryptography generateAndStoreNewAccountAuthenticationToken];
  // Testing storage
  NSLog(@"testing storage %@",[Cryptography getAuthenticationToken]);
  NSLog(@"testing out HMAC %@", [Cryptography computeSHA1DigestForString:@""]);
  
  // testing rn
//  NSData *data = [@"Data" dataUsingEncoding:NSUTF8StringEncoding];
//  NSError *error;
//  NSData *encryptedData = [RNEncryptor encryptData:data
//                                      withSettings:kRNCryptorAES256Settings
//                                          password:aPassword
//                                             error:&error];
 
}


-(void) markVerifiedPhone:(NSNotification*)notification {
  [UserDefaults markVerifiedPhone];
}

-(void) markSentVerification:(NSNotification*)notification {
  [UserDefaults markSentVerification];
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
  NSString *stringToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
  stringToken = [stringToken stringByReplacingOccurrencesOfString:@" " withString:@""];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SendAPN" object:self userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:stringToken,@"apnRegistrationId", nil]];


}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  // TODO: remove
  NSLog(@"GOT A PUSH!!!!");
  
}
@end
