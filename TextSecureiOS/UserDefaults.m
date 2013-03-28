//
//  UserDefaults.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "UserDefaults.h"

@implementation UserDefaults

+(BOOL) hasVerifiedPhone {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"hasVerifiedPhone"];
}

+(void) markVerifiedPhone {
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasVerifiedPhone"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}


+(BOOL) hasSentVerification {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"hasSentVerification"];
}

+(void) markSentVerification{
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasSentVerification"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
