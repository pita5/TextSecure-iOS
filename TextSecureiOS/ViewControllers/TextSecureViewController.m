//
//  ViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TextSecureViewController.h"
#import "UserDefaults.h"
#import "Message.h"
#import "Cryptography.h"
#import <AddressBookUI/AddressBookUI.h>
#import "BloomFilter.h"
#import "NSString+Conversion.h"
@implementation TextSecureViewController
@synthesize composingMessageText;
@synthesize messages;
@synthesize messagesDB;
- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationController.navigationBarHidden = NO;
  self.messagesDB = [[MessagesDatabase alloc] init];
  self.messages = [self.messagesDB getMessages];
  [self customizeUI];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadModel:) name:@"DatabaseUpdated" object:nil];
  self.title = @"Messages";
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
  [dateFormatter setDateFormat:@"HH:mm"];
  NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
  dateLabel.text = dateString;
  
  return cell;
}

-(void) customizeUI {
  [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed: @"TextSecure-Global-menubar.png"] forBarMetrics:UIBarMetricsDefault];
  [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:61.0/255.0 green:232.0/255.0 blue:56.0/255.0 alpha:0.0]];
  UIImage *composeImage = [UIImage imageNamed:@"TextSecure-Message-composebutton.png"];
  UIButton *composeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [composeButton setImage:composeImage forState:UIControlStateNormal];
  composeButton.showsTouchWhenHighlighted = YES;
  composeButton.frame = CGRectMake(0.0,0.0, 50.0, 50.0);
  [composeButton addTarget:self action:@selector(composeSMS:) forControlEvents:UIControlEventTouchUpInside];
  
  UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:composeButton];
  self.navigationItem.rightBarButtonItem = rightButton;
  
  self.tableView.backgroundColor = [UIColor clearColor];
  self.tableView.opaque = NO;
  
  
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
  BloomFilter *sharedBloomFilter = [[[UIApplication sharedApplication] delegate] performSelector:@selector(bloomFilter)];
  ABAddressBookRef addressBook = ABAddressBookCreate();
  __block BOOL accessGranted = NO;
  if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
      accessGranted = granted;
      dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
  }
  else { // we're on iOS 5 or older
    accessGranted = YES;
  }
  
  
  if (accessGranted) {
    ABAddressBookRef addressBook = ABAddressBookCreate();
    // Get all contacts from the address book
    NSArray *allPeople = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    int personId=0;
    for (id person in allPeople) {
      // Get all phone numbers of a contact
      ABMultiValueRef phoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)(person), kABPersonPhoneProperty);
      
      // If the contact has multiple phone numbers, iterate on each of them
      NSInteger phoneNumberCount = ABMultiValueGetCount(phoneNumbers);
      BOOL isContact=NO;
      for (int i = 0; i < phoneNumberCount; i++) {
        NSString *phoneNumberFromAB = [(__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, i) unformattedPhoneNumber];
        isContact =  isContact || [sharedBloomFilter containsUser:phoneNumberFromAB];
      }
      if(!isContact) {
        CFErrorRef err;
        // todo: causing memory corruption
        ABAddressBookRemoveRecord(addressBook,(__bridge ABRecordRef)(person), &err);
      }
      personId ++;
    }
    if(ABAddressBookGetPersonCount(addressBook)> 0) {
      ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
      NSNumber* emailProp = [NSNumber numberWithInt:kABPersonEmailProperty];
      [peoplePicker setAddressBook:addressBook];
      peoplePicker.displayedProperties = [NSArray arrayWithObject:emailProp];
      [peoplePicker setPeoplePickerDelegate:self];
      [peoplePicker.navigationBar setBackgroundImage:[UIImage imageNamed: @"TextSecure-Global-menubar.png"] forBarMetrics:UIBarMetricsDefault];
      [self presentViewController:peoplePicker animated:YES completion:NULL];
    }
  }
}


-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
  if(alertView.tag == 0) {
    self.composingMessagePhoneNumber = [alertView textFieldAtIndex:0].text;
    
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

#pragma mark contact picker UI
// Called after the user has pressed cancel
// The delegate is responsible for dismissing the peoplePicker
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

// Called after a person has been selected by the user.
// Return YES if you want the person to be displayed.
// Return NO  to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
  ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
  // If the contact has multiple phone numbers, iterate on each of them
  NSString *phoneNumberFromAB = [(__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, 0) unformattedPhoneNumber];
  self.composingMessagePhoneNumber=phoneNumberFromAB;
  [self dismissViewControllerAnimated:YES completion:NULL];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Message" delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil];
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  alert.tag = 1;
  [alert show];
  return NO;
}
// Called after a value has been selected by the user.
// Return YES if you want default action to be performed.
// Return NO to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
  //ABRecordRef phone =ABRecordCopyValue(person, property);
  //NSInteger phoneIdx = ABMultiValueGetIndexForIdentifier(phone,identifier);
  //NSString* phoneNumber = [(NSString*)CFBridgingRelease(ABMultiValueCopyValueAtIndex(phone,phoneIdx)) unformattedPhoneNumber];
  [self dismissViewControllerAnimated:YES completion:NULL];
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Message" delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil];
  alert.alertViewStyle = UIAlertViewStylePlainTextInput;
  alert.tag = 1;
  [alert show];
  
  return YES;
}



@end
