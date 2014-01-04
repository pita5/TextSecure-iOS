//
//  TSSetMasterPasswordViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSSetMasterPasswordViewController.h"
#import "TSStorageError.h"
#import "TSRegisterPrekeysRequest.h"
#import "TSUserKeysDatabase.h"
#import "TSStorageMasterKey.h"
#import "TSMessagesDatabase.h"

@interface TSSetMasterPasswordViewController ()

@end

@implementation TSSetMasterPasswordViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(setupDatabase)];
    
    self.navigationItem.rightBarButtonItem = self.nextButton;
    
    self.pass.delegate = self;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.pass becomeFirstResponder];
}


- (void) setupDatabase {
    NSError *error = nil;
    
    
    // Create and store the storage master key from the user's password so we can then create DBs
    if (![TSStorageMasterKey createStorageMasterKeyWithPassword:self.pass.text error:&error]) {
        @throw [NSException exceptionWithName:@"Storage master key creation failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    
    // Create the messages DB
    if(![TSMessagesDatabase databaseCreateWithError:nil]) {
        @throw [NSException exceptionWithName:@"Initial setup of messages DB failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    // Create the user keys DB and generate the user's identity key and prekeys
    if (![TSUserKeysDatabase databaseCreateUserKeysWithError:&error]) {
      @throw [NSException exceptionWithName:@"Initial setup of cryptography keys failed" reason:[error localizedDescription] userInfo:nil];
    }
  
    // Send the user's newly generated keys to the API
    // TODO: Error handling & retry if network error
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRegisterPrekeysRequest alloc] initWithPrekeyArray:[TSUserKeysDatabase getAllPreKeysWithError:nil] identityKey:[TSUserKeysDatabase getIdentityKeyWithError:nil]] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
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
