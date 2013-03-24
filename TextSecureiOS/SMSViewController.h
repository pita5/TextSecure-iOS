//
//  ViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMessageComposeViewController.h>


@interface SMSViewController : UITableViewController<ABPeoplePickerNavigationControllerDelegate,ABPersonViewControllerDelegate,MFMessageComposeViewControllerDelegate>
@property (nonatomic) int numItems;
@property (nonatomic, retain) NSArray *demoPhones;

- (IBAction)composeSMS:(id)sender;
- (IBAction) Edit:(id)sender;
@end
