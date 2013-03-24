//
//  VerificationViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "VerificationViewController.h"

@interface VerificationViewController ()

@end

@implementation VerificationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
  self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)verifiedPhone:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"VerifiedPhone" object:self];
  [self.navigationController popToRootViewControllerAnimated:YES];
}

-(IBAction)sentVerification:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SentVerification" object:self];
  [self performSegueWithIdentifier:@"ConfirmVerificationCode" sender:self];
}


@end
