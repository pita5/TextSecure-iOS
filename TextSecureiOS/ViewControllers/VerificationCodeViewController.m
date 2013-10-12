//
//  VerificationCodeViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "VerificationCodeViewController.h"
#import "TSServerCodeVerificationRequest.h"
#import "Cryptography.h"

@interface VerificationCodeViewController ()

@end

@implementation VerificationCodeViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doVerifyPhone:(id)sender {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedVerifiedPhone:) name:@"VerifiedPhone" object:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"VerifyAccount" object:self userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%@%@",_verificationCode_part1.text,_verificationCode_part2.text], @"verification_code", nil]];
    
    NSString* verificationCode = [_verificationCode_part1.text stringByAppendingString:_verificationCode_part2.text];
    
    [Cryptography generateAndStoreNewAccountAuthenticationToken];
    [Cryptography generateAndStoreNewSignalingKeyToken];
    
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSServerCodeVerificationRequest alloc] initWithVerificationCode:verificationCode] success:^(AFHTTPRequestOperation *operation, id responseObject){
        
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc]initWithTitle:@"Sorry we had an issue with this request" message:@"Read Dlog" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
    }];
    
}

-(void)finishedVerifiedPhone:(NSNotification*)notification {
	// register for push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
	 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	[self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
}

@end
