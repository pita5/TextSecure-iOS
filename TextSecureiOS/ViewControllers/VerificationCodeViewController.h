//
//  VerificationCodeViewController.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VerificationCodeViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic,strong) IBOutlet UITextField *verificationCode_part1;
@property (nonatomic,strong) IBOutlet UITextField *verificationCode_part2;

@property (nonatomic, strong) IBOutlet UIButton *sendAuthenticatedRequest;

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *basicAuthCode;

@end
