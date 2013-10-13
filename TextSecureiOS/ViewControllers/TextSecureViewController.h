//
//  TextSecureViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/30/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import "MessagesDatabase.h"

@interface TextSecureViewController : UIViewController<ABPeoplePickerNavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,strong) IBOutlet UITableView* tableView;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic,strong) MessagesDatabase *messagesDB;
@property (nonatomic,strong) NSString* composingMessagePhoneNumber;
@property (nonatomic,strong) NSString* composingMessageText;
- (IBAction) Edit:(id)sender;
@end

