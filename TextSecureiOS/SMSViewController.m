//
//  ViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "SMSViewController.h"
//

@implementation SMSViewController
@synthesize numItems;
@synthesize demoPhones;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    numItems = 10;
    demoPhones = [[NSArray alloc] initWithObjects:@"+16144868963",@"+41 79 962 44 99",@"+16144858953",@"+14154868963",@"+41 76 922 44 22",@"+12124868963",@"+15224224363",@"+13724224363",@"+14224224363",@"+17224224363",@"+19224224363", nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markVerifiedPhone:) name:@"VerifiedPhone" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markSentVerification:) name:@"SentVerification" object:nil];
  if(![self hasVerifiedPhone]){
     [self performSegueWithIdentifier:@"ObtainVerificationCode" sender:self];
  }
}

-(void)viewDidAppear:(BOOL)animated {
   self.navigationController.navigationBarHidden = NO;
}


- (IBAction)composeSMS:(id)sender {
  UIDevice *device = [UIDevice currentDevice];
  if ([[device model] isEqualToString:@"iPhone"] ) {
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate=self;
    
    [self presentViewController:picker animated:YES completion:nil];
  } else {
    // TODO: better backup for iPods (just don't support on)
    UIAlertView *Notpermitted=[[UIAlertView alloc] initWithTitle:@"Alert" message:@"Your device doesn't support this feature. " delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [Notpermitted show];
    
  }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
  [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

//- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//  // for custom designed cells
// 	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"TextSecureSMS"];
//  UILabel *phoneNumberLabel = (UILabel *)[cell viewWithTag:0];
//  UILabel *previewLabel = (UILabel *)[cell viewWithTag:1];
//  UILabel *dateLabel = (UILabel *)[cell viewWithTag:2];
//  return cell;
//}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // for default cells
 	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"TextSecureSMSDefault"];
  cell.textLabel.text = [self.demoPhones objectAtIndex:indexPath.row];
  cell.detailTextLabel.text = @"preview of sms written with TextSecure app";
  return cell;
}


- (void )tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"Selected a cell!");
  
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView  editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(self.editing == NO || !indexPath) {
		return UITableViewCellEditingStyleNone;
	}
	else {
		return UITableViewCellEditingStyleDelete;
  }
}


- (IBAction) Edit:(id)sender{
  if(self.editing) {
		[super setEditing:NO animated:NO];
		[self.tableView setEditing:NO animated:NO];
		[self.tableView reloadData];
    
  }
	else {
		[super setEditing:YES animated:YES];
		[self.tableView setEditing:YES animated:YES];
		[self.tableView reloadData];
  }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    if(self.numItems >= 1) {
      self.numItems-=1;
    }
		[tableView beginUpdates];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[tableView endUpdates];

    [self Edit:self];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		[self Edit:self];
	}
}
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section{
  return self.numItems;
}

-(BOOL) hasVerifiedPhone {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"hasVerifiedPhone"];
}

-(void) markVerifiedPhone:(NSNotification*)notification {
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasVerifiedPhone"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}


-(BOOL) hasSentVerification {
  return [[NSUserDefaults standardUserDefaults] boolForKey:@"hasSentVerification"];
}

-(void) markSentVerification:(NSNotification*)notification {
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasSentVerification"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}
        
@end
