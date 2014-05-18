//
//  TSContactProfileViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 5/18/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSContactProfileViewController.h"
#import "TSContact.h"
#import "TSVerifyIdentityViewController.h"
@interface TSContactProfileViewController ()

@end

@implementation TSContactProfileViewController

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
    if(!self.contact.identityKeyIsVerified && self.contact.identityKey) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Verify Identity" style:UIBarButtonItemStyleBordered target:self action:@selector(verifyIdentity:)];
    }
    if(self.contact.identityKey && !self.contact.identityKeyIsVerified) {
        self.navigationItem.rightBarButtonItem.enabled=YES;
        
    }

}


-(void)verifyIdentity:(id)sender {
    [self performSegueWithIdentifier:@"IdentityVerifySegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"IdentityVerifySegue"])  {
        
        ((TSVerifyIdentityViewController*)segue.destinationViewController).contact = self.contact;
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
