//
//  TSGroupSetupViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/8/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSGroupSetupViewController.h"
#import "ComposeMessageViewController.h"
#import "TSThread.h"
@interface TSGroupSetupViewController ()

@end

@implementation TSGroupSetupViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)next {
    [((UINavigationController*)self.navigationController.presentingViewController) pushViewController:[[ComposeMessageViewController alloc] initWithConversation:[TSThread threadWithContacts:self.groupContacts save:true]] animated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
