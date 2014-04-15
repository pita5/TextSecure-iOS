//
//  TSSetMasterPasswordViewController.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSSetMasterPasswordViewController : UIViewController<UITextFieldDelegate>

@property (nonatomic, copy) NSString *firstPass;
@property (nonatomic, strong) IBOutlet UITextField *pass;

@property (strong, nonatomic) IBOutlet UIButton *nextButton;

@property (nonatomic, retain) IBOutlet UILabel *instruction;

-(IBAction)nextWasTapped:(id)sender;

@end
