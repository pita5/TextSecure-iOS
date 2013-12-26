//
//  ViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TextSecureViewController.h"
#import "TSKeyManager.h"
#import "Cryptography.h"
#import <AddressBookUI/AddressBookUI.h>
#import "NSString+Conversion.h"
#import "TSSettingsViewController.h"
#import "TSContactManager.h"
#import "TSContact.h"
#import "ComposeMessageViewController.h"
#import "TSMessageThreadCell.h"

static NSString *kCellIdentifier = @"CellIdentifier";

static NSString *kThreadTitleKey = @"kThreadTitleKey";
static NSString *kThreadDateKey = @"kThreadDateKey";
static NSString *kThreadMessageKey = @"kThreadMessageKey";
static NSString *kThreadImageKey = @"kThreadImageKey";

@implementation TextSecureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = NO;
#warning we'll want to get messages from the message db here
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadModel:) name:@"DatabaseUpdated" object:nil];
    self.title = @"Messages";
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(openSettings)];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor : [UIColor colorWithRed:33/255. green:127/255. blue:248/255. alpha:1]} forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor grayColor]} forState:UIControlStateDisabled];
    
    self.navigationItem.leftBarButtonItem = settingsButton;
    
    UIBarButtonItem *composeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeMessage)];
    self.navigationItem.rightBarButtonItem = composeButton;
    
    
    self.messages = @[
                      @{kThreadTitleKey:@"Clément Duval", kThreadDateKey:@"26/12/13", kThreadMessageKey: @"Theft exists only through the exploitation of man by man... when Society refuses you the right to exist, you must take it... the policeman arrested me in the name of the Law, I struck him in the name of Liberty", kThreadImageKey: @"avatar_duval"},
                      @{kThreadTitleKey:@"Nestor Makhno", kThreadDateKey:@"25/12/13", kThreadMessageKey: @"need a ride?", kThreadImageKey: @"avatar_makhno"},
                      @{kThreadTitleKey:@"Wilhelm Reich", kThreadDateKey:@"24/12/13", kThreadMessageKey: @"Only the liberation of the natural capacity for love in human beings can master their sadistic destructiveness.", kThreadImageKey: @"avatar_reich"},
                      @{kThreadTitleKey:@"Masha Kolenkina", kThreadDateKey:@"22/12/13", kThreadMessageKey: @"Revenge, for it's own sake!", kThreadImageKey: @"avatar_kolenkina"},
                      @{kThreadTitleKey:@"Jules Bonnot", kThreadDateKey:@"20/12/13", kThreadMessageKey: @"Regrets, yes, but no remorce...", kThreadImageKey: @"avatar_bonnot"},
                      @{kThreadTitleKey:@"George Gurdjieff", kThreadDateKey:@"18/12/13", kThreadMessageKey: @"Levitation!", kThreadImageKey: @"avatar_gurdjieff"},
                      ];
    
    [self.tableView registerClass:[TSMessageThreadCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor lightGrayColor];
}

- (void) composeMessage {
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[[ComposeMessageViewController alloc]initNewConversation]] animated:YES completion:nil];
}

- (void) openSettings {
    [self performSegueWithIdentifier:@"openSettings" sender:self];
}

// for custom designed cells
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
 	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if ([cell isKindOfClass:[TSMessageThreadCell class]]) {
        
        NSDictionary *messageDict = self.messages[indexPath.row];
        
        TSMessageThreadCell *threadCell = (TSMessageThreadCell *)cell;
        threadCell.titleLabel.text = messageDict[kThreadTitleKey];
        threadCell.timestampLabel.text = messageDict[kThreadDateKey];
        threadCell.threadPreviewLabel.text = messageDict[kThreadMessageKey];
        
        UIImage *disclosureIndicatorImage = [[UIImage imageNamed:@"disclosure_indicator"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        threadCell.disclosureImageView.image = disclosureIndicatorImage;
        
        NSString *imageName = messageDict[kThreadImageKey];
        threadCell.threadImageView.image = [UIImage imageNamed:imageName];
    }
        
    return cell;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    if(![TSKeyManager hasVerifiedPhoneNumber]){
        [self performSegueWithIdentifier:@"ObtainVerificationCode" sender:self];
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 74.0f;
}

-(void) reloadModel:(NSNotification*)notification {
#warning get the messages from the database here
    [self.tableView reloadData];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 0) {
        self.composingMessagePhoneNumber = [alertView textFieldAtIndex:0].text;
        
    }
    else if(alertView.tag==1) {
        self.composingMessageText=[alertView textFieldAtIndex:0].text;
#warning send message here
#warning add message to database here
        self.composingMessageText = nil;
        self.composingMessagePhoneNumber = nil;
    }
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
