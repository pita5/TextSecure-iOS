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
    for (int i = 0; i < number.count; i++) {
        if (4 == i || 7 == i) { // account for dashes in these positions
            range.location++;
        }
        [self.controller textField:phoneNumber shouldChangeCharactersInRange:range replacementString:[number objectAtIndex:i]];
        range.location++;
    }
    
    NSString *expectedPhoneNUmber = @"212-736-5000";
    XCTAssert([phoneNumber.text isEqualToString:expectedPhoneNUmber], @"phoneNumber does not match expected value");
}

@end
