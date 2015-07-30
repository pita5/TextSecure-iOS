//
//  VerificationViewControllerTests.m
//  TextSecureiOS
//
//  Created by Troy Farrell on 2/25/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VerificationViewController.h"

@interface VerificationViewControllerTests : XCTestCase
@property (strong, nonatomic) VerificationViewController *controller;
@end

// Steal this private method for testing.
@interface VerificationViewController ()
-(void)setLocaleCountry;
@end

@implementation VerificationViewControllerTests

- (void)setUp
{
    [super setUp];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    self.controller = [storyboard instantiateViewControllerWithIdentifier:@"VerificationViewController"];
    [self.controller performSelectorOnMainThread:@selector(loadView) withObject:nil waitUntilDone:YES];
}

- (void)tearDown
{
    self.controller = nil;
    [super tearDown];
}

// This test verifies that entering a basic US phone number works
-(void)testBasicUSPhoneNumber
{
    // Focus and set the countryCodeInput.
    UITextField *countryCodeInput = self.controller.countryCodeInput;
    [self.controller textFieldShouldBeginEditing:countryCodeInput];
    countryCodeInput.text = @"+1";
    
    // Focus and set the phoneNumber.
    UITextField *phoneNumber = self.controller.phoneNumber;
    NSRange range = NSMakeRange(0, 0);
    NSArray *number = @[@"2", @"1", @"2", @"7", @"3", @"6", @"5", @"0", @"0", @"0"];
    [self.controller textFieldShouldBeginEditing:phoneNumber];
    for (NSUInteger i = 0; i < number.count; i++) {
        if (4 == i || 7 == i) { // account for dashes in these positions
            range.location++;
        }
        [self.controller textField:phoneNumber shouldChangeCharactersInRange:range replacementString:[number objectAtIndex:i]];
        range.location++;
    }
    
    NSString *expectedPhoneNUmber = @"212-736-5000";
    XCTAssert([phoneNumber.text isEqualToString:expectedPhoneNUmber], @"phoneNumber does not match expected value");
}

// This test is to ensure that the countryCodeInput is never empty.  This is
// a related, but separate issue to the -(void)testEmptyCountryCodeCrash
// test.
- (void)testEmptyCountryCodeInputPrevention
{
    // Pretend that the view controller became visible.
    [self.controller setLocaleCountry];
    
    // Focus on the countryCodeInput.  This causes the existing text to be
    // cleared.
    UITextField *countryCodeInput = self.controller.countryCodeInput;
    [self.controller textFieldShouldBeginEditing:countryCodeInput];
    
    // Verify that the countryCodeInput text field has only a +.
    XCTAssert([countryCodeInput.text isEqualToString:@"+"], @"countryCodeInput text is not only a +");
    
    // Stop editing the text field.
    [self.controller textFieldDidEndEditing:countryCodeInput];

    // The countryCodeInput text must not be @"" or @"+".
    XCTAssert(countryCodeInput.text.length > 1, @"countryCodeInput text is too short.");
    XCTAssert([[countryCodeInput.text substringToIndex:1] isEqualToString:@"+"], @"countryCodeInput text does not start with +");

    NSString *numbersPart = [countryCodeInput.text substringFromIndex:1];
    NSCharacterSet *numbers = [NSCharacterSet decimalDigitCharacterSet];
    NSRange range = [numbersPart rangeOfCharacterFromSet:numbers];

    XCTAssert(range.location != NSNotFound, @"countryCodeInput text does not contain a digit");
}

// This test is to ensure that focusing on the countryCodeInput after
// selecting a country does not cause the country code to be hidden.
-(void)testCountrySelectAfterFocusingCountryCodeInput
{
    // Pretend that the view controller became visible.
    [self.controller setLocaleCountry];
    
    // Focus, set and blur the countryCodeInput.
    UITextField *countryCodeInput = self.controller.countryCodeInput;
    [self.controller textFieldShouldBeginEditing:countryCodeInput];
    countryCodeInput.text = @"+33";
    [self.controller textFieldDidEndEditing:countryCodeInput];
    XCTAssert([countryCodeInput.text isEqualToString:@"+33"], @"countryCodeInput text does not match set value");
    
    // Pretend that user selected a country from the CountryViewController.
    NSString *plistFile = [[NSBundle mainBundle] pathForResource:countryInfoPathInMainBundle ofType:@"plist"];
    NSDictionary *countryDict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFile];
    NSArray *countryList = [[countryDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSString *countryTitleForAndorra = [countryList objectAtIndex:4];
    NSDictionary *countryInfoForAndorra = [countryDict objectForKey:countryTitleForAndorra];
    [self.controller countryChosen:[NSNotification notificationWithName:@"CountryChosen" object:nil userInfo:countryInfoForAndorra]];
    
    // On exiting the CountryViewController, the countryCodeInput is
    // selected again.  This time, it should not replace the country code
    // that was just selected.
    [self.controller textFieldShouldBeginEditing:countryCodeInput];
    NSString *expectedCountryCode = [NSString stringWithFormat:@"+%@",[countryInfoForAndorra objectForKey:countryInfoKeyCountryCode]];
    XCTAssert([countryCodeInput.text isEqualToString:expectedCountryCode], @"countryCodeInput text does not match selected country info");
}

@end
