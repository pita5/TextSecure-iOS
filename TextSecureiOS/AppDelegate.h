//
//  AppDelegate.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"
#import "MessagesDatabase.h"
#import "BloomFilter.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) Server *server;
@property (strong,nonatomic) MessagesDatabase *messageDatabase;
@property (strong,nonatomic) BloomFilter *bloomFilter;
-(void) handlePush:(NSDictionary *)pushInfo;
@end
