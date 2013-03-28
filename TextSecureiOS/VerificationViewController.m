//
//  VerificationViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "VerificationViewController.h"

@interface VerificationViewController ()

@end

@implementation VerificationViewController
@synthesize phoneNumber;
@synthesize countryCode;
@synthesize countryName;

@synthesize verificationCodePart1;
@synthesize verificationCodePart2;
@synthesize selectedPhoneNumber;
@synthesize flag;
@synthesize scrollView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
	// Do any additional setup after loading the view.
  self.verificationCodePart2.delegate = self;
  self.verificationCodePart1.delegate = self;
  self.title = selectedPhoneNumber;
  self.flag.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",@"us"]];
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(countryChosen:) name:@"CountryChosen" object:nil];
  [self registerForKeyboardNotifications];

}


-(void) countryChosen:(NSNotification*)notification {
  NSLog(@"country chosen");
  NSDictionary *countryInfo = [notification userInfo];
  self.flag.image=[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[countryInfo objectForKey:@"code"]]];
  self.countryCode.text = [countryInfo objectForKey:@"country_code"];
  self.countryName.titleLabel.text=[countryInfo objectForKey:@"name"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doVerifyPhone:(id)sender {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedVerifiedPhone:) name:@"VerifiedPhone" object:nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"VerifyAccount" object:self userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%@%@",verificationCodePart1.text,verificationCodePart2.text], @"verification_code", nil]];
}

-(void)finishedVerifiedPhone:(NSNotification*)notification {
  // register for push notifications
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
   (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
  [self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
  
}

-(void)finishedSendVerification:(NSNotification*)notification {
  [self performSegueWithIdentifier:@"ConfirmVerificationCode" sender:self];
}

-(IBAction)sentVerification:(id)sender {
  self.selectedPhoneNumber = [NSString stringWithFormat:@"+%@%@",self.countryCode.text,self.phoneNumber.text];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateAccount" object:self userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:self.self.selectedPhoneNumber, @"username", nil]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedSendVerification:) name:@"SentVerification" object:nil];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
  if([segue.identifier isEqualToString:@"ConfirmVerificationCode"]){
    VerificationViewController *controller = (VerificationViewController *)segue.destinationViewController;
    controller.selectedPhoneNumber= self.selectedPhoneNumber;
  }
}

#define MAX_LENGTH 3 // Whatever your limit is
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  //TODO: not called
  NSUInteger newLength = (textView.text.length - range.length) + text.length;
  if(newLength <= MAX_LENGTH) {
    return YES;
  } else {
    NSUInteger emptySpace = MAX_LENGTH - (textView.text.length - range.length);
    textView.text = [[[textView.text substringToIndex:range.location]
                      stringByAppendingString:[text substringToIndex:emptySpace]]
                     stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
    return NO;
  }
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
  NSDictionary* info = [aNotification userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
  scrollView.contentInset = contentInsets;
  scrollView.scrollIndicatorInsets = contentInsets;
  
  // If active text field is hidden by keyboard, scroll it so it's visible
  // Your application might not need or want this behavior.
  CGRect aRect = self.view.frame;
  aRect.size.height -= kbSize.height;
  UITextField *textField;
  if(phoneNumber!=NULL) {
    textField=phoneNumber;
  }
  else {
    textField = verificationCodePart1;
  }
  if (!CGRectContainsPoint(aRect, textField.frame.origin) ) {
    // iPhone 5 hack :( TODO: figure out how to remove
    float offset = 0.0;
    CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
    if (iOSDeviceScreenSize.height == 568)  {
      offset = -68.0;
    }
    CGPoint scrollPoint = CGPointMake(0.0, textField.frame.origin.y-kbSize.height+offset);
    NSLog(@"scroll point is %f",textField.frame.origin.y);
    [scrollView setContentOffset:scrollPoint animated:YES];
  }
}


- (void)registerForKeyboardNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasShown:)
                                               name:UIKeyboardDidShowNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillBeHidden:)
                                               name:UIKeyboardWillHideNotification object:nil];
  
}


// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  scrollView.contentInset = contentInsets;
  scrollView.scrollIndicatorInsets = contentInsets;
}


@end
