//
//  TSSetMasterPasswordViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSSetMasterPasswordViewController.h"
#import "TSEncryptedDatabase.h"
#import "TSRegisterPrekeys.h"

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
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(setupDatabase)];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor : [UIColor colorWithRed:33/255. green:127/255. blue:248/255. alpha:1]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor grayColor]} forState:UIControlStateDisabled];
    
    self.navigationItem.rightBarButtonItem = nextButton;
}

- (void) viewDidAppear:(BOOL)animated{
    [self.pass becomeFirstResponder];
}

- (void) setupDatabase {
    // Create the database on the device
    NSError *error = nil;
    // TODO: Error handling
    TSEncryptedDatabase *encDb = [TSEncryptedDatabase databaseCreateWithPassword:self.pass.text error:&error];
    if(!encDb) {
        @throw [NSException exceptionWithName:@"DB creation failed" reason:[error localizedDescription] userInfo:nil];
    }
    
    // Send the user's newly generated keys to the API
    // TODO: Error handling & retry if network error
    __block BOOL sendSuccess = NO;
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRegisterPrekeys alloc] initWithPrekeyArray:[encDb getPersonalPrekeys] identityKey:[encDb getIdentityKey]] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (operation.response.statusCode == 200) {
            sendSuccess = YES;
        }
        DLog(@"response %d, %@",operation.response.statusCode,operation.response.description);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"failure %d, %@",operation.response.statusCode,operation.response.description);
    }];
    if (!sendSuccess) {
        @throw [NSException exceptionWithName:@"setup database error" reason:@"could not send the user's keys to the server" userInfo:nil];
        }
    else {
        [self performSegueWithIdentifier:@"BeginUsingApp" sender:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
