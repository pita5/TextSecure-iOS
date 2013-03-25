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
@property (nonatomic,strong) Server *verificationServer;
@property (nonatomic,strong) IBOutlet UITextField *countryCode;
@property (nonatomic,strong) IBOutlet UITextField *phoneNumber;
@property (nonatomic,strong) IBOutlet UITextField *verificationCodePart1;
@property (nonatomic,strong) IBOutlet UITextField *verificationCodePart2;
@property (nonatomic,strong) NSString* selectedPhoneNumber;
-(IBAction)doVerifyPhone:(id)sender;
-(IBAction)verifiedPhone:(NSNotification*)notification;

-(IBAction)sentVerification:(id)sender;

@end
