//
//  UnlockViewControllerTests.m
//  TextSecureiOS
//
//  Created by Daniel Witurna on 28.02.14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PasswordUnlockViewController.h"
#import "TSStorageMasterKey.h"

@interface PasswordUnlockViewControllerTests : XCTestCase
@property (strong, nonatomic) PasswordUnlockViewController *controller;
@end

static NSString *masterPw = @"1234test";

// Get access to private delegate methods and textfield for testing.
@interface PasswordUnlockViewController () <UITextFieldDelegate>
@property(nonatomic, strong) IBOutlet UITextField *passwordTextField;
@end

@implementation PasswordUnlockViewControllerTests

- (void)setUp
{
    [super setUp];
    
    NSError *err = nil;
    //Setup storage key master and lock it.
    [TSStorageMasterKey eraseStorageMasterKey];
    [TSStorageMasterKey createStorageMasterKeyWithPassword:masterPw error:&err];
    [TSStorageMasterKey lockStorageMasterKey];
    
    XCTAssertNil(err, @"Creating storage master key failed.");
 
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    self.controller = [storyboard instantiateViewControllerWithIdentifier:@"PasswordUnlockViewController"];
    [self.controller performSelectorOnMainThread:@selector(loadView) withObject:nil waitUntilDone:YES];
}

- (void)tearDown
{
    self.controller = nil;
    [super tearDown];
}

- (void)testEnterCorrectPassword
{
    UITextField *passwordTextField = self.controller.passwordTextField;
    NSString *correctPassword = masterPw;
    passwordTextField.text = correctPassword;
    
    [self.controller textFieldShouldReturn:passwordTextField]; //Triggers unlock button press

    BOOL didUnlock = ![TSStorageMasterKey isStorageMasterKeyLocked];

    XCTAssertTrue(didUnlock, @"Password unlock with correct password failed");
}

- (void)testEnterWrongPassword
{
    UITextField *passwordTextField = self.controller.passwordTextField;
    NSString *wrongPassword = @"test1234";
    passwordTextField.text = wrongPassword;
    
    [self.controller textFieldShouldReturn:passwordTextField]; //Triggers unlock button press
    
    BOOL didUnlock = ![TSStorageMasterKey isStorageMasterKeyLocked];
    
    XCTAssertFalse(didUnlock, @"Password unlock with wrong password succeeded");
}

- (void)testEnterEmptyPassword
{
    UITextField *passwordTextField = self.controller.passwordTextField;
    NSString *wrongPassword = @"";
    passwordTextField.text = wrongPassword;
    
    [self.controller textFieldShouldReturn:passwordTextField]; //Triggers unlock button press
    
    BOOL didUnlock = ![TSStorageMasterKey isStorageMasterKeyLocked];
    
    XCTAssertFalse(didUnlock, @"Password unlock with wrong password succeeded");
}

- (void)testNilPassword
{
    UITextField *passwordTextField = self.controller.passwordTextField;
    NSString *wrongPassword = nil;
    passwordTextField.text = wrongPassword;
    
    [self.controller textFieldShouldReturn:passwordTextField]; //Triggers unlock button press
    
    BOOL didUnlock = ![TSStorageMasterKey isStorageMasterKeyLocked];
    
    XCTAssertFalse(didUnlock, @"Password unlock with wrong password succeeded");
}


@end