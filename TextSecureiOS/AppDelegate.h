//
//  AppDelegate.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessagesDatabase.h"

#ifdef DEBUG
@interface AppDelegate : UIResponder <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate, UIApplicationDelegate>
#else
@interface AppDelegate : UIResponder <UIApplicationDelegate>
#endif


@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) MessagesDatabase *messageDatabase;
-(void) handlePush:(NSDictionary *)pushInfo;
@end
