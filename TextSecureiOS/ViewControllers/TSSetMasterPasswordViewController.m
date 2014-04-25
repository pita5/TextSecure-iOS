//
//  TSSetMasterPasswordViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSSetMasterPasswordViewController.h"
#import "TSStorageError.h"
#import "TSRegisterPrekeysRequest.h"
#import "TSUserKeysDatabase.h"
#import "TSStorageMasterKey.h"
#import "TSMessagesDatabase.h"
#import "TSWaitingPushMessageDatabase.h"
#import "TSECKeyPair.h"
#import "RMStepsController.h"
#import <Navajo/NJOPasswordStrengthEvaluator.h>


#define pickPassword @"Pick your password"
#define reenterPassword @"Please re-enter your password"


@interface TSSetMasterPasswordViewController ()
@property (readwrite, nonatomic, strong) NJOPasswordValidator *lenientValidator;

@end

@implementation TSSetMasterPasswordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create validator with custom rule because +standardValidator has a minimum length of 6
    self.lenientValidator = [NJOPasswordValidator validatorWithRules:@[[NJOLengthRule ruleWithRange:NSMakeRange(1, 128)]]];
    
    self.nextButton.enabled = NO;
    
    self.pass.delegate = self;
    
    self.instruction.text = pickPassword;
    self.navigationController.navigationBarHidden = YES;

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.pass becomeFirstResponder];
}


- (IBAction) nextWasTapped:(id)sender{
    if (self.firstPass == nil) {
        self.firstPass = self.pass.text;
        self.instruction.text = reenterPassword;
        self.pass.text = @"";
		self.nextButton.enabled = NO;
        self.passwordStrengthLabel.text = @"";
        self.pass.keyboardType = UIKeyboardTypeAlphabet;
        self.passwordStrengthMeterView.progress = 0.f;
        self.passwordStrengthMeterView.tintColor = [UIColor TSInvalidColor];

    } else {
        if ([self.pass.text isEqualToString:self.firstPass]) {
            [self setupDatabase];
            // remember state to present the right keyboard to the user
            [[NSUserDefaults standardUserDefaults] setBool:self.alphanumericalSwitch.on forKey:kPasswordIsAlphanumerical];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else{
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Passwords don't match" message:@"Both entered passwords don't match. Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            self.firstPass = nil;
            self.pass.text = @"";
            self.passwordStrengthMeterView.progress = 0.f;
            self.passwordStrengthMeterView.tintColor = [UIColor TSInvalidColor];
            [self.pass becomeFirstResponder];
            self.instruction.text = pickPassword;
        }
    }
}

- (IBAction)skipWasTapped:(id)sender {
    // TODO: improve message to help user with making an informed decision
    // TODO: decide whether an implementation of a block based UI-AlertView should be included as Pod
    NSString *message = NSLocalizedString(@"If no master password is set, your database is only encrypted by iOS Data Protection. Do you want to proceed without setting a password?", nil);
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Data encryption", nil) message:message
                              delegate:self cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles:NSLocalizedString(@"Yes", nil), nil] show];
}

- (IBAction)pinSwitchHasChanged:(UISwitch *)sender {
    if (sender.on) {
        self.pass.keyboardType = UIKeyboardTypeDefault;
    } else {
        self.pass.keyboardType = UIKeyboardTypeNumberPad;
    }
    [self.pass resignFirstResponder];
    [self.pass becomeFirstResponder];
}

- (void) setupDatabase {
    NSError *error = nil;
    
    
    // Create and store the storage master key from the user's password so we can then create DBs
    if (![TSStorageMasterKey createStorageMasterKeyWithPassword:self.pass.text error:&error]) {
        @throw [NSException exceptionWithName:@"Storage master key creation failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    // Create the messages DB
    if(![TSMessagesDatabase databaseCreateWithError:&error]) {
        @throw [NSException exceptionWithName:@"Initial setup of messages DB failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    // Create the user keys DB and generate the user's identity key and prekeys
    if (![TSUserKeysDatabase databaseCreateUserKeysWithError:&error]) {
        @throw [NSException exceptionWithName:@"Initial setup of cryptography keys failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    if(![TSWaitingPushMessageDatabase databaseCreateWaitingPushMessageDatabaseWithError:&error]) {
        @throw [NSException exceptionWithName:@"Initial setup of waiting push message database failed" reason:[error localizedDescription] userInfo:nil];        
    }
    
    // Send the user's newly generated keys to the API
    // TODO: Error handling & retry if network error
    
    NSArray *preKeys = [TSUserKeysDatabase allPreKeys];
    TSECKeyPair *identityKey = [TSUserKeysDatabase identityKey];
    
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRegisterPrekeysRequest alloc] initWithPrekeyArray:preKeys identityKey:identityKey] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        switch (operation.response.statusCode) {
            case 200:
            case 204:
                DLog(@"Device registered prekeys");
                break;
                
            default:
                DLog(@"Issue registering prekeys response %zd, %@",operation.response.statusCode,operation.response.description);
#warning Add error handling if not able to send the prekeys
                break;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
        DLog(@"failure %zd, %@",operation.response.statusCode,operation.response.description);
    }];

    [self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

	// What's the password field going to contain if we let this change occur?
	NSString *newPass = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    // Update password strenght for the new password
    [self updatePasswordStrength:self forPassword:newPass];
    
    if (newPass.length > 0) {
        self.nextButton.enabled = YES;
    } else {
        self.nextButton.enabled = NO;
    }

    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Password strength
- (void)updatePasswordStrength:(id)sender forPassword:(NSString*)password {
    
    if ([password length] == 0) {
        self.passwordStrengthMeterView.progress = 0.0f;
        self.passwordStrengthLabel.text = NSLocalizedString(@"Invalid Password", nil) ;
    } else {
        NJOPasswordStrength strength = [NJOPasswordStrengthEvaluator strengthOfPassword:password];
        self.passwordStrengthLabel.text = [NJOPasswordStrengthEvaluator localizedStringForPasswordStrength:strength];
        if ([self.lenientValidator validatePassword:password failingRules:nil]) {
            switch (strength) {
                case NJOVeryWeakPasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.1f;
                    self.passwordStrengthMeterView.tintColor = [UIColor TSInvalidColor];
                    break;
                case NJOWeakPasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.25f;
                    self.passwordStrengthMeterView.tintColor = [UIColor TSOrangeWarningColor];
                    break;
                case NJOReasonablePasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.5f;
                    self.passwordStrengthMeterView.tintColor = [UIColor TSYellowWarningColor];
                    break;
                case NJOStrongPasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.75f;
                    self.passwordStrengthMeterView.tintColor = [UIColor TSValidColor];
                    break;
                case NJOVeryStrongPasswordStrength:
                    self.passwordStrengthMeterView.progress = 1.0f;
                    self.passwordStrengthMeterView.tintColor = [UIColor TSValidColor];
                    break;
            }
            
        } else {
            self.passwordStrengthLabel.text = NSLocalizedString(@"Invalid Password", nil);
            self.passwordStrengthMeterView.progress = 0.1f;
            self.passwordStrengthMeterView.tintColor = [UIColor redColor];
        }
    }
}

#pragma mark - AlertView delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedString(@"Yes", nil)]) {
        self.pass.text = @"";
        [self setupDatabase];
        
        // remember state so user does not need to unlock the app
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPasswordNotSet];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } 
    
    
}

@end
