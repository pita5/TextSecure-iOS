//
//  AppDelegate.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef DEBUG
@interface AppDelegate : UIResponder <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate, UIApplicationDelegate>
#else
@interface AppDelegate : UIResponder <UIApplicationDelegate>
#endif


@property (strong, nonatomic) UIWindow *window;

// used to obscure the application when the user backgrounds it
@property (strong, nonatomic) UIWindow *blankWindow;

@end
