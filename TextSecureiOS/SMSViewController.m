//
//  ViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "SMSViewController.h"
#import "UserDefaults.h"
#import "Message.h"
#import "Cryptography.h"
@implementation SMSViewController
@synthesize composingMessageText;
@synthesize messages;
@synthesize messagesDB;
- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationController.navigationBarHidden = NO;
  self.messagesDB = [[MessagesDatabase alloc] init];
  self.messages = [self.messagesDB getMessages];
  [self customizeMenuBar];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadModel:) name:@"DatabaseUpdated" object:nil];
}

-(void) customizeMenuBar {
  [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed: @"TextSecure-Messages-menubar.png"] forBarMetrics:UIBarMetricsDefault];

  UIImage *composeImage = [UIImage imageNamed:@"TextSecure-Messages-composebutton.png"];
  UIButton *composeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [composeButton setImage:composeImage forState:UIControlStateNormal];
  composeButton.showsTouchWhenHighlighted = YES;
  composeButton.frame = CGRectMake(0.0,0.0, 50.0, 50.0);
  
  [composeButton addTarget:self action:@selector(composeSMS:) forControlEvents:UIControlEventTouchUpInside];
  
  UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:composeButton];
  self.navigationItem.rightBarButtonItem = rightButton;

  
}

-(void)viewDidAppear:(BOOL)animated {
   self.navigationController.navigationBarHidden = NO;
  if(![UserDefaults hasVerifiedPhone]){
    [self performSegueWithIdentifier:@"ObtainVerificationCode" sender:self];
  }

}

-(void) reloadModel:(NSNotification*)notification {
  self.messages=[self.messagesDB getMessages];
  [self.tableView reloadData];
}

- (IBAction)composeSMS:(id)sender {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Phone Number" message:@"Phone" delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil];
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  alert.tag = 0;
  [alert show];
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
  NSLog(@"%@", [alertView textFieldAtIndex:0].text);
  if(alertView.tag == 0) {
    self.composingMessagePhoneNumber = [alertView textFieldAtIndex:0].text;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Message" delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 1;
    [alert show];
  }
  else if(alertView.tag==1) {
    self.composingMessageText=[alertView textFieldAtIndex:0].text;
    Message *newMessage = [[Message alloc]
                           initWithText:self.composingMessageText
                           messageSource:[Cryptography getUsernameToken]
                           messageDestinations:[[NSArray alloc] initWithObjects:self.composingMessagePhoneNumber,nil]
                           messageAttachments:[[NSArray alloc] init]
                           messageTimestamp:[NSDate date]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SendMessage" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newMessage, @"message",nil]];
    [self.messagesDB addMessage:newMessage];
    self.composingMessageText = nil;
    self.composingMessagePhoneNumber = nil;
  }
}



 // for custom designed cells
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // for custom designed cells
 	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"TextSecureSMS"];
  UILabel *phoneNumberLabel = (UILabel *)[cell viewWithTag:1];
  UILabel *previewLabel = (UILabel *)[cell viewWithTag:2];
  UILabel *dateLabel = (UILabel *)[cell viewWithTag:3];
  
  Message* message = [self.messages objectAtIndex:indexPath.row];
  phoneNumberLabel.text = [message.destinations objectAtIndex:0];
  previewLabel.text = message.text;
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"MM/DD HH:mm"];
  NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
  dateLabel.text = dateString;

  return cell;
}


/* for default cells
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // for default cells
 	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"TextSecureSMSDefault"];
  Message* message = [self.messages objectAtIndex:indexPath.row];
  cell.textLabel.text = [message.destinations objectAtIndex:0];
  cell.detailTextLabel.text = message.text;
  return cell;
}
 */


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
    // TODO: update with ability to delete
    [self Edit:self];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		[self Edit:self];
	}
}
- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section{
  return [self.messages count];
}

        
@end
