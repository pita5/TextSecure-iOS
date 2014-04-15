//
//  SignUpStepsViewController.m
//  TextSecureiOS
//
//  Created by Dylan Bourgeois on 15/04/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "SignUpStepsViewController.h"
#import "VerificationViewController.h"
#import "VerificationCodeViewController.h"
#import "TSSetMasterPasswordViewController.h"


@implementation SignUpStepsViewController

- (NSArray *)stepViewControllers {
    VerificationViewController *firstStep = [self.storyboard instantiateViewControllerWithIdentifier:@"VerificationViewController"];
    firstStep.step.title = @"Number";
    
    VerificationCodeViewController *secondStep = [self.storyboard instantiateViewControllerWithIdentifier:@"VerificationCodeViewController"];
    secondStep.step.title = @"Code";

    TSSetMasterPasswordViewController *thirdStep = [self.storyboard instantiateViewControllerWithIdentifier:@"TSSetMasterPasswordViewController"];
    thirdStep.step.title = @"Password";
    
    return @[firstStep, secondStep, thirdStep];
}

- (void)finishedAllSteps {
    [self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
}

- (void)canceled {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
