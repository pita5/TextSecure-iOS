//
//  CountrySegue.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "CountrySegue.h"

@implementation CountrySegue

- (void) perform {
  UIViewController *src = (UIViewController *) self.sourceViewController;
  [src.navigationController popViewControllerAnimated:YES];
}
@end
