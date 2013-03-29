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
#import "MessagesDatabase.h"


@interface SMSViewController : UITableViewController
@property (nonatomic, retain) NSArray *messages;
@property (nonatomic,retain) MessagesDatabase *messagesDB;
@property (nonatomic,retain) NSString* composingMessagePhoneNumber;
@property (nonatomic,retain) NSString* composingMessageText;
- (IBAction) Edit:(id)sender;
@end
