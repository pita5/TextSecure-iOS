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
    
    self.verificationCode_part1.delegate = self;
    self.verificationCode_part2.delegate = self;
}

- (void) viewDidAppear:(BOOL)animated{
    [self.verificationCode_part1 becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITextFieldDelegateMethod

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField == self.verificationCode_part1 && ![string isEqualToString:@""] && range.location == 2 && string.length == 1) {
        [self.verificationCode_part2 becomeFirstResponder];
        self.verificationCode_part1.text = [self.verificationCode_part1.text stringByAppendingString:string];
        return NO;
    } else if (textField == self.verificationCode_part2 && ![string isEqualToString:@""] && range.location == 2 && string.length == 1){
        self.verificationCode_part2.text = [self.verificationCode_part2.text stringByAppendingString:string];
        [self.verificationCode_part2 resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark Code verification

-(IBAction)doVerifyPhone:(id)sender {
    
    NSString* verificationCode = [_verificationCode_part1.text stringByAppendingString:_verificationCode_part2.text];
    
    NSString *authToken = [Cryptography generateNewAccountAuthenticationToken];
    NSString *signalingKey = [Cryptography generateNewSignalingKeyToken];
    
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSServerCodeVerificationRequest alloc] initWithVerificationCode:verificationCode signalingKey:signalingKey authToken:authToken] success:^(AFHTTPRequestOperation *operation, id responseObject){
        
        switch (operation.response.statusCode) {
            case 403:
                
                //403 is the code that's being sent back by the PendingAccountVerificationFailedException if the verification code is wrong
                
                [[[UIAlertView alloc]initWithTitle:@"Can't verify" message:@"The entered code doesn't appear to match the one on our servers. Try entering it again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
                
                break;
                
            case 200:
                
                NSLog(@"Saving storageKey: %@", authToken);
            
                [Cryptography storeSignalingKeyToken:signalingKey];
                [Cryptography storeAuthenticationToken:authToken];
                
                NSLog(@"Recovering key: %@", [Cryptography getAuthenticationToken]);
                
                [self performSegueWithIdentifier:@"setMasterPassword" sender:self];
                
                break;
                
            default:
                [[[UIAlertView alloc]initWithTitle:@"Can't verify" message:@"An unknown error occured. Pleasy try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
                break;
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        defaultNetworkErrorMessage
    }];
}

-(void)finishedVerifiedPhone:(NSNotification*)notification {
	// register for push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
	 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	[self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
}

@end
