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
@synthesize countryCodeInput;
@synthesize verifyButton;

@synthesize explanationText;
@synthesize youPhoneNumberText;
@synthesize youPhoneNumberTextDescription;
@synthesize findCountryCodeText;
@synthesize findCountryCodeTextDescription;
@synthesize verificationTextExplanation;
@synthesize verificationCompletionExplanation;
@synthesize countryDict;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    return self;
}

-(void) configureFonts {
  /*
   "OpenSans-Light",
   "OpenSans-Extrabold",
   OpenSans,
   "OpenSans-Italic",
   "OpenSansLight-Italic",
   "OpenSans-Semibold",
   "OpenSans-SemiboldItalic",
   "OpenSans-Bold",
   "OpenSans-BoldItalic",
   "OpenSans-ExtraboldItalic"
   */
  [countryCode setFont:[UIFont fontWithName:@"OpenSans" size:14]];
  [countryCodeInput setFont:[UIFont fontWithName:@"OpenSans" size:20]];
  [phoneNumber setFont:[UIFont fontWithName:@"OpenSans" size:20]];
  [verificationCodePart1 setFont:[UIFont fontWithName:@"OpenSans" size:20]];
  [verificationCodePart2 setFont:[UIFont fontWithName:@"OpenSans" size:20]];
  [explanationText setFont:[UIFont fontWithName:@"OpenSans" size:14]];
  [youPhoneNumberText setFont:[UIFont fontWithName:@"OpenSans" size:14]];
  [youPhoneNumberTextDescription setFont:[UIFont fontWithName:@"OpenSans" size:10]];
  [findCountryCodeText setFont:[UIFont fontWithName:@"OpenSans" size:14]];
  [findCountryCodeTextDescription setFont:[UIFont fontWithName:@"OpenSans" size:10]];

  [verificationTextExplanation setFont:[UIFont fontWithName:@"OpenSans" size:20]];
  [verificationCompletionExplanation setFont:[UIFont fontWithName:@"OpenSans" size:20]];

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
  [self configureFonts];
  [countryCodeInput addTarget:self action:@selector(updateCountryCode:) forControlEvents:UIControlEventEditingChanged];
  self.countryDict = [[NSMutableDictionary alloc]  initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CountryCodes" ofType:@"plist"]];
 
  // also key by country code
  for (NSString* key in [self.countryDict allKeys]) {
    // TODO: save this reoriganization
    NSDictionary* data =[self.countryDict objectForKey:key];
    [self.countryDict setObject:data forKey:[data objectForKey:@"country_code"]];
  }


}

-(void)updateCountryCode:(id)sender {
  if ([self.countryDict objectForKey:self.countryCodeInput.text]) {
    NSLog(@"country found %@",[self.countryDict objectForKey:self.countryCodeInput.text]);
    [self updateCountry:[self.countryDict objectForKey:self.countryCodeInput.text]];
  }
}

-(void)updateCountry:(NSDictionary*)countryInfo {
  self.flag.image=[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[[countryInfo objectForKey:@"code"] lowercaseString]]];
  self.countryCode.text = [NSString stringWithFormat:@"[+%@]",[countryInfo objectForKey:@"country_code"]];
  self.countryCodeInput.text = [countryInfo objectForKey:@"country_code"];
  self.countryName.text=[countryInfo objectForKey:@"name"];

}

-(void) countryChosen:(NSNotification*)notification {
  NSLog(@"country chosen");
  [self updateCountry:[notification userInfo]];
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
  
  // If verify button field is hidden by keyboard, scroll it so it's visible
  // Your application might not need or want this behavior.
  CGRect aRect = self.view.frame;
  CGPoint aPoint;
  aRect.size.height -= kbSize.height;
  if(phoneNumber!=NULL) {
    aPoint = self.verifyButton.frame.origin;
  }
  else {
    aPoint = verificationCodePart1.frame.origin;
  }
  if (CGRectContainsPoint(aRect, aPoint )) {
    // iPhone 5 hack :( TODO: figure out how to remove
    float offset = 0.0;
    CGSize iOSDeviceScreenSize = [[UIScreen mainScreen] bounds].size;
    if (iOSDeviceScreenSize.height == 568)  {
      offset = -68.0;
    }
    CGPoint scrollPoint = CGPointMake(0.0, aPoint.y+kbSize.height+offset);
   
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
