//
//  VerificationViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"
#import "NBAsYouTypeFormatter.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"


@interface VerificationViewController : UIViewController<UITextFieldDelegate>
@property (nonatomic,strong) IBOutlet UITextField *countryCodeInput;
@property (nonatomic,strong) IBOutlet UILabel *countryName;
@property (nonatomic,strong) IBOutlet UITextField *phoneNumber;
@property (nonatomic,strong) IBOutlet UITextField *verificationCodePart1;
@property (nonatomic,strong) IBOutlet UITextField *verificationCodePart2;

@property (nonatomic, strong) IBOutlet UILabel *explanationText;
@property (nonatomic, retain) NBAsYouTypeFormatter *numberFormatter;

@property (nonatomic,strong) IBOutlet UILabel *verificationTextExplanation;
@property (nonatomic,strong) IBOutlet UILabel *verificationCompletionExplanation;

@property (nonatomic, copy) NSString *selectedPhoneNumber;

-(IBAction)doVerifyPhone:(id)sender;
-(void) countryChosen:(NSNotification*)notification;
- (void)didReceiveMemoryWarning;
-(void)finishedVerifiedPhone:(NSNotification*)notification;
-(void)finishedSendVerification:(NSNotification*)notification;
-(IBAction)sendVerification:(id)sender;
-(void)updateCountry:(NSDictionary*)countryInfo;
@end


