//
//  TSSetMasterPasswordViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSSetMasterPasswordViewController.h"
#import "TSEncryptedDatabase.h"
#import "TSEncryptedDatabaseError.h"
#import "TSRegisterPrekeysRequest.h"

@interface TSSetMasterPasswordViewController ()

@end

@implementation TSSetMasterPasswordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(setupDatabase)];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor : [UIColor colorWithRed:33/255. green:127/255. blue:248/255. alpha:1]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor grayColor]} forState:UIControlStateDisabled];
    
    self.navigationItem.rightBarButtonItem = self.nextButton;
    
    self.pass.delegate = self;
}

- (void) viewDidAppear:(BOOL)animated{
    [self.pass becomeFirstResponder];
}


- (void) setupDatabase {
    // Create the database on the device
    NSError *error = nil;
    
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:self.pass.text error:&error];
    if(!encDb) {
        if ([[error domain] isEqualToString:TSEncryptedDatabaseErrorDomain]) {
            switch ([error code]) {
                case DbCreationFailed:
                    // TODO: Proper error handling
                    @throw [NSException exceptionWithName:@"DB creation failed" reason:[error localizedDescription] userInfo:nil];
            }
        }
    }
    
    // Send the user's newly generated keys to the API
    // TODO: Error handling & retry if network error
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRegisterPrekeysRequest alloc] initWithPrekeyArray:[encDb getPersonalPrekeys] identityKey:[encDb getIdentityKey]] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        switch (operation.response.statusCode) {
            case 200:
            case 204:
            DLog(@"Device registered prekeys");
            break;
            
            default:
            DLog(@"Issue registering prekeys response %d, %@",operation.response.statusCode,operation.response.description);
#warning Add error handling if not able to send the prekeys
            break;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
        DLog(@"failure %d, %@",operation.response.statusCode,operation.response.description);
    }];
    
    [self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([textField.text isEqualToString:@""]) {
        // Application password shouldn't be empty
        self.nextButton.enabled = NO;
    } else{
        self.nextButton.enabled = YES;
    }
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
