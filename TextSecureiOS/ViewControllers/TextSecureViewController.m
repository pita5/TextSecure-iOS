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
#import "NSString+Conversion.h"
#import "TSSettingsViewController.h"
#import "TSContactManager.h"

@implementation TextSecureViewController
@synthesize composingMessageText;
@synthesize messages;
@synthesize messagesDB;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    //self.messagesDB = [[MessagesDatabase alloc] init];
    //self.messages = [self.messagesDB getMessages];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadModel:) name:@"DatabaseUpdated" object:nil];
    self.title = @"Messages";
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(openSettings)];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor : [UIColor colorWithRed:33/255. green:127/255. blue:248/255. alpha:1]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor grayColor]} forState:UIControlStateDisabled];
    
    self.navigationItem.leftBarButtonItem = settingsButton;
    
    UIBarButtonItem *create = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(composeMessage)];
    self.navigationItem.rightBarButtonItem = create;
}

- (void) composeMessage{
    [TSContactManager getAllContactsIDs];
}

- (void) openSettings{
    [self performSegueWithIdentifier:@"openSettings" sender:self];
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

-(void)viewDidAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    if(![UserDefaults hasVerifiedPhoneNumber]){
        [self performSegueWithIdentifier:@"ObtainVerificationCode" sender:self];
    }
    
}

-(void) reloadModel:(NSNotification*)notification {
    self.messages=[self.messagesDB getMessages];
    [self.tableView reloadData];
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
