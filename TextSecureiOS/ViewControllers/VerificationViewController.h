//
//  VerificationViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"
@interface VerificationViewController : UIViewController<UITextFieldDelegate>
@property (nonatomic,strong) IBOutlet UILabel *countryCode;
@property (nonatomic,strong) IBOutlet UITextField *countryCodeInput;
@property (nonatomic,strong) IBOutlet UILabel *countryName;
@property (nonatomic,strong) IBOutlet UITextField *phoneNumber;
@property (nonatomic,strong) IBOutlet UITextField *verificationCodePart1;
@property (nonatomic,strong) IBOutlet UITextField *verificationCodePart2;
@property (nonatomic,strong) IBOutlet UIImageView  *flag;
@property (nonatomic,strong) IBOutlet UIButton *verifyButton;
@property (nonatomic,strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic,strong) IBOutlet UILabel *explanationText;
@property (nonatomic,strong) IBOutlet UILabel *youPhoneNumberText;
@property (nonatomic,strong) IBOutlet UILabel *youPhoneNumberTextDescription;
@property (nonatomic,strong) IBOutlet UILabel *findCountryCodeText;
@property (nonatomic,strong) IBOutlet UILabel *findCountryCodeTextDescription;

@property (nonatomic,strong) IBOutlet UILabel *verificationTextExplanation;
@property (nonatomic,strong) IBOutlet UILabel *verificationCompletionExplanation;


@property (nonatomic,strong) NSString* selectedPhoneNumber;
@property (nonatomic,strong) IBOutlet UILabel* selectedPhoneNumberLabel;
@property (nonatomic,strong) NSMutableDictionary* countryDict;
@property (nonatomic,strong) UITextField *activeField;

-(IBAction)doVerifyPhone:(id)sender;
-(void) countryChosen:(NSNotification*)notification;
- (void)didReceiveMemoryWarning;
-(void) registerForKeyboardNotifications;
-(void)finishedVerifiedPhone:(NSNotification*)notification;
-(void)finishedSendVerification:(NSNotification*)notification;
-(IBAction)sentVerification:(id)sender;
-(void)updateCountry:(NSDictionary*)countryInfo;
@end


