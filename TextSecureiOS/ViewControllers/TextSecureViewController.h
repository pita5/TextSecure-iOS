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

@interface TextSecureViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, copy) NSString *composingMessagePhoneNumber;
@property (nonatomic, copy) NSString *composingMessageText;

- (IBAction) Edit:(id)sender;
@end

