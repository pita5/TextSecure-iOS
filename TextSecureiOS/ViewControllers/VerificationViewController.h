//
//  VerificationViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "NBAsYouTypeFormatter.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"


@interface VerificationViewController : UIViewController<UITextFieldDelegate>
@property (nonatomic,strong) IBOutlet UITextField *countryCodeInput;
@property (nonatomic,strong) IBOutlet UILabel *countryName;
@property (nonatomic,strong) IBOutlet UITextField *phoneNumber;

@property (nonatomic, strong) IBOutlet UILabel *explanationText;
@property (nonatomic, retain) NBAsYouTypeFormatter *numberFormatter;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *nextButton;
@property (strong, nonatomic) IBOutlet UIView *underlineNumberView;
@property (strong, nonatomic) IBOutlet UIView *underlineCountryCodeView;

@property (nonatomic, copy) NSString *selectedPhoneNumber;

-(void) countryChosen:(NSNotification*)notification;
- (void)didReceiveMemoryWarning;
-(void)updateCountry:(NSDictionary*)countryInfo;

-(IBAction)sendVerification:(id)sender;
@end