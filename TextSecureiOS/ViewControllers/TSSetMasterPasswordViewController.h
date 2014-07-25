//
//  TSSetMasterPasswordViewController.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPasswordIsAlphanumerical @"PasswordIsAlphanumerical"

@interface TSSetMasterPasswordViewController : UIViewController<UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, copy) NSString *firstPass;
@property (nonatomic, strong) IBOutlet UITextField *pass;

@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) IBOutlet UIButton *skipButton;

@property (strong, nonatomic) IBOutlet UISwitch *alphanumericalSwitch;

@property (nonatomic, retain) IBOutlet UILabel *instruction;

@property (weak, nonatomic) IBOutlet UIProgressView *passwordStrengthMeterView;
@property (nonatomic, retain) IBOutlet UILabel *passwordStrengthLabel;

-(IBAction)nextWasTapped:(id)sender;

@end
