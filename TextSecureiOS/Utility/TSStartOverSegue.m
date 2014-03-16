//
//  TSStartOverSegue.m
//  TextSecureiOS
//
//  Created by Daniel Cestari on 3/15/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSStartOverSegue.h"

// lossly based on: http://stackoverflow.com/a/21415225/452964

@implementation TSStartOverSegue

- (void)perform
{
    UIViewController *sourceViewController  = self.sourceViewController;
    UIViewController *destinationController = self.destinationViewController;
    UINavigationController *navigationController = sourceViewController.navigationController;

    [navigationController setViewControllers:@[destinationController] animated:YES];
}

@end
