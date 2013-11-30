//
//  TSSetMasterPasswordViewController.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSSetMasterPasswordViewController : UIViewController<UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITextField *pass;
@property (nonatomic, strong) UIBarButtonItem *nextButton;

@end
