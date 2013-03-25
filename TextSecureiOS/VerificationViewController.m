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
@synthesize verificationServer;
@synthesize phoneNumber;
@synthesize countryCode;
@synthesize verificationCodePart1;
@synthesize verificationCodePart2;
@synthesize selectedPhoneNumber;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view.
  self.verificationServer = [[Server alloc] init];
  self.verificationCodePart2.delegate = self;
  self.verificationCodePart1.delegate = self;
  self.title = selectedPhoneNumber;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doVerifyPhone:(id)sender {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedVerifiedPhone:) name:@"VerifiedPhone" object:nil];
  [self.verificationServer doVerifyAccount:selectedPhoneNumber verificationCode:[NSString stringWithFormat:@"%@%@",verificationCodePart1.text,verificationCodePart2.text]];

}

-(void)finishedVerifiedPhone:(NSNotification*)notification {
  [self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
  
}

-(void)finishedSendVerification:(NSNotification*)notification {
  [self performSegueWithIdentifier:@"ConfirmVerificationCode" sender:self];
}

-(IBAction)sentVerification:(id)sender {
  self.selectedPhoneNumber= [NSString stringWithFormat:@"%@%@",countryCode.text,phoneNumber.text];
  [self.verificationServer doCreateAccount:self.selectedPhoneNumber];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SentVerification" object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedSendVerification:) name:@"VerifiedPhone" object:nil];
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

@end
