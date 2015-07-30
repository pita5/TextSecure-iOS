//
//  TSReplaceSegue.m
//  TextSecureiOS
//
//  Created by Daniel Cestari on 3/12/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSReplaceSegue.h"

// lossly based on: http://stackoverflow.com/a/21415225/452964

@implementation TSReplaceSegue

- (void)perform
{
    UIViewController *sourceViewController  = self.sourceViewController;
    UIViewController *destinationController = self.destinationViewController;
    UINavigationController *navigationController = sourceViewController.navigationController;

    [navigationController popToRootViewControllerAnimated:NO];
    [navigationController pushViewController:destinationController animated:YES];
}

@end
