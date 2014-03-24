//
//  VerificationCodeViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "VerificationCodeViewController.h"
#import "TSServerCodeVerificationRequest.h"
#import "TSKeyManager.h"

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

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.verificationCode_part1.delegate = self;
    self.verificationCode_part2.delegate = self;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.verificationCode_part1 becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITextFieldDelegateMethod

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
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
    
    NSString *authToken = [TSKeyManager generateNewAccountAuthenticationToken];
    NSString *signalingKey = [TSKeyManager generateNewSignalingKeyToken];
    
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSServerCodeVerificationRequest alloc] initWithVerificationCode:verificationCode signalingKey:signalingKey authToken:authToken] success:^(AFHTTPRequestOperation *operation, id responseObject){
        
        switch (operation.response.statusCode) {
            case 204:
                
                [TSKeyManager storeSignalingKeyToken:signalingKey];
                [TSKeyManager storeAuthenticationToken:authToken];

                [self performSegueWithIdentifier:@"setMasterPassword" sender:self];
                
                // Perform the APN registration
                
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
                
                break;
                
            default:
                [[[UIAlertView alloc]initWithTitle:@"Can't verify" message:@"An unknown error occured. Pleasy try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
                DLog(@"Verification operation failed with response: %@ and response code : %li", responseObject, operation.response.statusCode);
                break;
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 403) {
            [[[UIAlertView alloc]initWithTitle:@"Wrong code" message:@"The entered code doesn't appear to match the one on our servers. Try entering it again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
        } else{
            defaultNetworkErrorMessage
        }
        DLog(@"Verification operation request failed with error: %@", error);
    }];
}



-(IBAction)doRequestPhoneVerification:(id)sender {

    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRequestVerificationCodeRequest alloc] initRequestForPhoneNumber:[TSKeyManager getUsernameToken] transport:kPhoneNumberVerification] success:^(AFHTTPRequestOperation *operation, id responseObject){
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[[UIAlertView alloc]initWithTitle:@"Sorry we had an issue with this request" message:@"Read Dlog" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
    }];

  
}



@end
