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
// Note there are so many IBOutlets to support easy Localizable.strings localization
// and customization of fonts. Hopefully this will be made easier in the future iOS dev
// suite to be done entirely via Storyboards and not via code. If anyone has a cleaner way
// of doing this, please go ahead.
@synthesize phoneNumber;

@synthesize countryName;
@synthesize verificationCodePart1;
@synthesize verificationCodePart2;
@synthesize countryCodeInput;
@synthesize explanationText;
@synthesize verificationTextExplanation;
@synthesize verificationCompletionExplanation;


- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
	self.verificationCodePart2.delegate = self;
	self.verificationCodePart1.delegate = self;
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(countryChosen:) name:@"CountryChosen" object:nil];
	[countryCodeInput addTarget:self action:@selector(updateCountryCode:) forControlEvents:UIControlEventEditingChanged];
    
    
    [self setLocaleCountry];
    
    [self.phoneNumber becomeFirstResponder];
    
}

// Based on the user's locale we are guessing what his country code would be.

-(void)setLocaleCountry{
    DLog(@"Setting Locale to : %@", [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]);
    
    self.countryCodeInput.text = [NSLocale currentCountryPhonePrefix];
    [self updateCountryCode:nil];
}

-(void)updateCountryCode:(id)sender {
    NSString *enteredCountryCode = self.countryCodeInput.text;
    enteredCountryCode = [enteredCountryCode removeAllFormattingButNumbers];
    
    [self updateCountry:@{@"country_code":enteredCountryCode, @"name":[[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:[NSLocale localizedCodeNameForPhonePrefix:enteredCountryCode]]}];
}

-(void)updateCountry:(NSDictionary*)countryInfo {
	self.countryCodeInput.text = [[countryInfo objectForKey:@"country_code"] prependPlus];
	self.countryName.text=[countryInfo objectForKey:@"name"];
}

-(void) countryChosen:(NSNotification*)notification {
	[self updateCountry:[notification userInfo]];
}

- (void)nextButtonWasPressed:(id)sender{
	[self.phoneNumber becomeFirstResponder];
}

- (void)doneButtonWasPressed:(id)sender {
    [self.phoneNumber resignFirstResponder];
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
    //self.selectedPhoneNumber = [NSString stringWithFormat:@"+%@%@",self.countryCodeInput.text,self.phoneNumber.text];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"CreateAccount" object:self userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:self.self.selectedPhoneNumber, @"username",@"sms",@"transport",nil]]; // should be one of sms,voice
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedSendVerification:) name:@"SentVerification" object:nil];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    //	if([segue.identifier isEqualToString:@"ConfirmVerificationCode"]){
    //		VerificationViewController *controller = (VerificationViewController *)segue.destinationViewController;
    //		controller.selectedPhoneNumber= self.selectedPhoneNumber;
    //	}
}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    if ([textField isEqual:self.countryCodeInput]) {
        self.countryCodeInput.text = @"+";
        [self updateCountryCode:nil];
    } else if ([textField isEqual:self.phoneNumber]){
        [self initNumberFormatter];
    }
    
    return YES;
}

-(void) initNumberFormatter{
    self.numberFormatter = [[NBAsYouTypeFormatter alloc]initWithRegionCode:[NSLocale localizedCodeNameForPhonePrefix:[self.countryCodeInput.text removeAllFormattingButNumbers]]];
    
    NSString *charString = [[countryCodeInput.text removeAllFormattingButNumbers] prependPlus];
    
    for (int i = 0; i < charString.length; i++) {
        [self.numberFormatter inputDigit:[charString substringWithRange:NSMakeRange(i, 1)]];
    }
}

#define MAX_LENGTH 4 // Whatever your limit is
- (BOOL)textField:(UITextView *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
	
    if ([textField isEqual:self.countryCodeInput]) {
        NSUInteger newLength = (textField.text.length - range.length) + string.length;
        if(newLength < MAX_LENGTH) {
            return YES;
        } else {
            NSUInteger emptySpace = MAX_LENGTH - (textField.text.length - range.length);
            textField.text = [[[textField.text substringToIndex:range.location]
                               stringByAppendingString:[string substringToIndex:emptySpace]]
                              stringByAppendingString:[textField.text substringFromIndex:(range.location + range.length)]];
            [self.phoneNumber becomeFirstResponder];
            [self updateCountryCode:nil];
            return NO;
        }
        
    } else if ([textField isEqual:self.phoneNumber]){
        
        if ([string isEqualToString:@""]) {
            // A character is deleted. We rebuild the formatter with one fewer char
            [self initNumberFormatter];
            
            NSString *formattedString;
            
            NSString *nonFormattedstring = [self.phoneNumber.text removeAllFormattingButNumbers];
            
            for (int i = 0; i < (nonFormattedstring.length - 1) ; i++) {
                formattedString = [self.numberFormatter inputDigit:[nonFormattedstring substringWithRange:NSMakeRange(i, 1)]];
            }
            
            self.phoneNumber.text = [self cleanPrefixOfString:formattedString];
            
        } else{
            NSString *formattedString =[self.numberFormatter inputDigit:string];
            DLog(@"Parsed phone number string: %@", formattedString);
            self.phoneNumber.text = [self cleanPrefixOfString:formattedString];
        }
        return NO;
        
    } else {
        return YES;
    }
}


// The parsing library needs to see the phone number with the prefix, we do show it without it.
// This ugly method clean the prefix so that phone number fields is parsed but without prefix.

-(NSString*) cleanPrefixOfString:(NSString*)formattedText{
    
    NSMutableArray *prefix = [NSMutableArray array];
    NSString *prefixString = [[countryCodeInput.text removeAllFormattingButNumbers] prependPlus];
    
    for (int i = 0; i < prefixString.length; i++) {
        [prefix addObject:[prefixString substringWithRange:NSMakeRange(i, 1)]];
    }
    
    int lastCharLoc = 0;
    
    for (int i = 0; i < formattedText.length; i++) {
        if ([[formattedText substringWithRange:NSMakeRange(i, 1)] isEqualToString:[prefix firstObject]]) {
            [prefix removeObjectAtIndex:0];
        
            if (prefix.count == 0) {
                lastCharLoc = i;
            }
        }
    }
    
    if (lastCharLoc < formattedText.length) {
        if (!isnumber([formattedText characterAtIndex:(lastCharLoc+1)])) {
            lastCharLoc++;
        }
    }
    
    return [formattedText substringWithRange:NSMakeRange(lastCharLoc+1, formattedText.length-(lastCharLoc+1))];
}

@end
