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
    
    self.lenientValidator = [NJOPasswordValidator standardValidator];
    
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
        self.entropyLabel.text = @"Entropy : 0 bits";
        self.passwordStrengthMeterView.progress = 0.f;
        self.passwordStrengthMeterView.tintColor = [UIColor TSInvalidColor];

    } else {
        if ([self.pass.text isEqualToString:self.firstPass]) {
            [self setupDatabase];
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

    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Password strength
- (void)updatePasswordStrength:(id)sender forPassword:(NSString*)password {
    
    // disable next button, will be enabled when password strength is reasonable
    // TODO: define a password policy that should be enforced
    self.nextButton.enabled = NO;
    
    if ([password length] == 0) {
        self.passwordStrengthMeterView.progress = 0.0f;
        self.passwordStrengthLabel.text = NSLocalizedString(@"Invalid Password", nil) ;
        self.entropyLabel.text = [NSString stringWithFormat:@"Entropy : 0 bits"];
    } else {
        NJOPasswordStrength strength = [NJOPasswordStrengthEvaluator strengthOfPassword:password];
        self.passwordStrengthLabel.text = [NJOPasswordStrengthEvaluator localizedStringForPasswordStrength:strength];
        self.entropyLabel.text = [NSString stringWithFormat:@"Entropy : %.2f bits", NJOEntropyForString(password)];
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
                    self.nextButton.enabled = YES;
                    break;
                case NJOStrongPasswordStrength:
                    self.passwordStrengthMeterView.progress = 0.75f;
                    self.passwordStrengthMeterView.tintColor = [UIColor TSValidColor];
                    self.nextButton.enabled = YES;
                    break;
                case NJOVeryStrongPasswordStrength:
                    self.passwordStrengthMeterView.progress = 1.0f;
                    self.passwordStrengthMeterView.tintColor = [UIColor TSValidColor];
                    self.nextButton.enabled = YES;
                    break;
            }
            
        } else {
            self.passwordStrengthLabel.text = NSLocalizedString(@"Invalid Password", nil);
            self.passwordStrengthMeterView.progress = 0.1f;
            self.passwordStrengthMeterView.tintColor = [UIColor redColor];
        }
    }
}

@end
