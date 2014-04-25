//
//  PasswordUnlockViewController.m
//  TextSecureiOS
//
//  Created by Claudiu-Vlad Ursache on 29/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "PasswordUnlockViewController.h"
#import "TSUserKeysDatabase.h"
#import "TSStorageMasterKey.h"
#import "TSStorageError.h"
#import "TSMessagesDatabase.h"
#import "TSWaitingPushMessageDatabase.h"
#import "TSSetMasterPasswordViewController.h"

@interface PasswordUnlockViewController () <UITextFieldDelegate>
@property(nonatomic, strong) IBOutlet UITextField *passwordTextField;
@end

@implementation PasswordUnlockViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kPasswordIsAlphanumerical]) {
        
        self.passwordTextField.keyboardType = UIKeyboardTypeNumberPad;
        
        // number pad does not provide UIReturnKeyGo, so use a accessory view
        UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
        UIBarButtonItem *switchKeyboards = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"alphanumeric", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(switchKeyboardToAlphanumeric)];
        UIBarButtonItem *spacer = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *goButton = [[UIBarButtonItem alloc] initWithTitle:@"Go"
                                                                       style:UIBarButtonItemStyleDone target:self
                                                                      action:@selector(doneTapped)];
        [keyboardDoneButtonView setItems:@[switchKeyboards, spacer, goButton]];
        [keyboardDoneButtonView sizeToFit];
        self.passwordTextField.inputAccessoryView = keyboardDoneButtonView;
    }

    self.passwordTextField.placeholder = @"Please enter your password";
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    [self.passwordTextField becomeFirstResponder];
    self.passwordTextField.delegate = self;
}

- (IBAction)unlockPressed:(id)sender {
    
    NSString *password = self.passwordTextField.text;

    NSError *error = nil;
    [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:password error:&error];
    BOOL didUnlock = ![TSStorageMasterKey isStorageMasterKeyLocked];

    if (didUnlock) {
        self.pwUnderlineView.backgroundColor = [UIColor TSValidColor];
        [[NSNotificationCenter defaultCenter] postNotificationName:TSDatabaseDidUnlockNotification object:self];
        [self dismissViewControllerAnimated:YES completion:nil];
       
    } else {
        if ([[error domain] isEqualToString:TSStorageErrorDomain]) {
            switch ([error code]) {
                case TSStorageErrorInvalidPassword: {
                    [self shake:self.padView];
                    self.passwordTextField.text = nil;
                    self.passwordTextField.placeholder = @"Please try again.";

                    break;
                }
                default: {
                    // TODO: proper error handling

                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:error.localizedDescription
                                                                       delegate:self
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                    [alertView show];

                    break;
                }
            }
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [self unlockPressed:textField];

    return YES;
}

#pragma mark - Keyboard Accessory View

- (void)doneTapped {
    [self unlockPressed:self.passwordTextField];
}

- (void)switchKeyboardToAlphanumeric {
    self.passwordTextField.keyboardType = UIKeyboardTypeDefault;
    self.passwordTextField.inputAccessoryView = nil;
    [self.passwordTextField resignFirstResponder];
    [self.passwordTextField becomeFirstResponder];
}

#pragma mark - Shake if password incorrect
- (void)shake:(UIImageView*)imageView
{
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.05];
    [animation setRepeatCount:4];
    [animation setAutoreverses:YES];
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake([imageView center].x - 10.0f, [imageView center].y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake([imageView center].x + 10.0f, [imageView center].y)]];
    [[imageView layer] addAnimation:animation forKey:@"position"];
}

@end
