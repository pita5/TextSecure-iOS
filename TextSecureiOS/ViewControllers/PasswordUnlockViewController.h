//
//  PasswordUnlockViewController.h
//  TextSecureiOS
//
//  Created by Claudiu-Vlad Ursache on 29/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PasswordUnlockViewController : UIViewController <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UIView *pwUnderlineView;
@property (strong, nonatomic) IBOutlet UIImageView *padView;

@end
