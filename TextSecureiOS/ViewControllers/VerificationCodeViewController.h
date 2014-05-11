//
//  VerificationCodeViewController.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NBAsYouTypeFormatter.h"

@interface VerificationCodeViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic,strong) IBOutlet UITextField *verificationCode_part1;
@property (nonatomic,strong) IBOutlet UITextField *verificationCode_part2;
@property (strong, nonatomic) IBOutlet UILabel *smsToNumberLabel;

@property (nonatomic, strong) IBOutlet UIButton *sendAuthenticatedRequest;
@property (strong, nonatomic) IBOutlet UIView *underlineView1;
@property (strong, nonatomic) IBOutlet UIView *underlineView2;

@property (nonatomic, retain) NBAsYouTypeFormatter *numberFormatter;

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *basicAuthCode;

@end
