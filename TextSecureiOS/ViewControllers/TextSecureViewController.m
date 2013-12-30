//
//  ViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TextSecureViewController.h"
#import "Cryptography.h"
#import "TSMessagesDatabase.h"
#import <AddressBookUI/AddressBookUI.h>
#import "NSString+Conversion.h"
#import "TSSettingsViewController.h"
#import "TSContactManager.h"
#import "TSContact.h"
#import "TSMessage.h"
#import "ComposeMessageViewController.h"
#import "TSMessageThreadCell.h"

static NSString *kCellIdentifier = @"CellIdentifier";

static NSString *kThreadTitleKey = @"kThreadTitleKey";
static NSString *kThreadDateKey = @"kThreadDateKey";
static NSString *kThreadMessageKey = @"kThreadMessageKey";
static NSString *kThreadImageKey = @"kThreadImageKey";

@interface TextSecureViewController() <SWTableViewCellDelegate>
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *composeBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *settingsBarButtonItem;
@property (nonatomic, strong) UIView *searchBarCoverView;
@end

@implementation TextSecureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Messages";
    self.navigationController.navigationBarHidden = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadModel:) name:TSDatabaseDidUpdateNotification object:nil];
    
    self.settingsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(openSettings)];
    self.navigationItem.leftBarButtonItem = self.settingsBarButtonItem;
    
    self.composeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeMessage)];
    self.navigationItem.rightBarButtonItem = self.composeBarButtonItem;
    
    self.searchBarCoverView = [[UIView alloc] initWithFrame:self.searchBar.bounds];
    self.searchBarCoverView.backgroundColor = [UIColor grayColor];
    self.searchBarCoverView.alpha = 0;
    self.searchBarCoverView.userInteractionEnabled = NO;
    [self.searchBar addSubview:self.searchBarCoverView];
    
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


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    if(![TSKeyManager hasVerifiedPhoneNumber]){
        [self performSegueWithIdentifier:@"ObtainVerificationCode" sender:self];
    }
    
}

- (void)composeMessage {
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[[ComposeMessageViewController alloc]initNewConversation]] animated:YES completion:nil];
}

- (void)openSettings {
    [self performSegueWithIdentifier:@"openSettings" sender:self];
}

#pragma mark - UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
   /*
    //sketch of using database data getMessagesOnThread and getThreads
    // need fleshed out (currently schema is 1 thread only) --corbett
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
  
  
    TSEncryptedDatabase *cryptoDB = [TSEncryptedDatabase database];
    TSMessage* message=[[cryptoDB getMessagesOnThread:indexPath.row] objectAtIndex:0];
    if(message!=nil) {
      phoneNumberLabel.text = message.senderId;
      previewLabel.text = message.message;
      NSString *dateString = [dateFormatter stringFromDate:message.messageTimestamp];
      dateLabel.text = dateString;
    }
    */

 	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if ([cell isKindOfClass:[TSMessageThreadCell class]]) {
        
        NSDictionary *messageDict = self.messages[indexPath.row];
        
        TSMessageThreadCell *threadCell = (TSMessageThreadCell *)cell;
        threadCell.titleLabel.text = messageDict[kThreadTitleKey];
        threadCell.timestampLabel.text = messageDict[kThreadDateKey];
        threadCell.threadPreviewLabel.text = messageDict[kThreadMessageKey];
        
        UIImage *disclosureIndicatorImage = [[UIImage imageNamed:@"disclosure_indicator"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        threadCell.disclosureImageView.image = disclosureIndicatorImage;
        
        NSMutableArray *rightUtilityButtons = [[NSMutableArray alloc] init];
        UIColor *deleteButtonColor = [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f];
        [rightUtilityButtons sw_addUtilityButtonWithColor:deleteButtonColor title:@"Delete"];
        
        threadCell.rightUtilityButtons = rightUtilityButtons;
        threadCell.delegate = self;
        threadCell.containingTableView = tv;
        threadCell.cellHeight = [self tableView:tv heightForRowAtIndexPath:indexPath];
    }
        
    return cell;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section{
    /*
     //sketch of using database data getMessagesOnThread and getThreads
     // need fleshed out (currently schema is 1 thread only) --corbett
     if(![TSEncryptedDatabase isLockedOrNotCreated]) {
     TSEncryptedDatabase *cryptoDB = [TSEncryptedDatabase database];
     return [[cryptoDB getThreads] count];
     }
     else {
     return 0;
     }
     */
    if([TSMessagesDatabase databaseWasCreated]) {
        // don't display until db is unlocked (we have "dummy data" right now, but this better mimics UX behavior)
        return [self.messages count];
    }
    else {
        return 0;
    }
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 74.0f;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView  editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(self.editing == NO || !indexPath) {
		return UITableViewCellEditingStyleNone;
	}
	else {
		return UITableViewCellEditingStyleDelete;
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

-(void) reloadModel:(NSNotification*)notification {
// sketch of using database
//    if([TSMessagesDatabase databaseWasCreated] == YES) {
//        NSArray *messagesOnThread = [TSMessagesDatabase getMessagesOnThread:0];
//        if (messagesOnThread && [messagesOnThread count] ) {
//            TSMessage *message = [messagesOnThread objectAtIndex:0];
//        }
//        
//        NSArray *allThreads = [TSMessagesDatabase getThreads];
//        NSLog(@"allThreads.count: %d", allThreads.count);
//    }
//    
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

- (IBAction) Edit:(id)sender {
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

#pragma mark - SWTableViewCellDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    // Remove item here
    
    [self animateEnteringEditingMode:NO];
}

// This SWTableViewCell delegate method is still buggy and doesn't represent the exact state of the cell,
// e.g. when the right utility buttons are not set.
// TODO: Fix bugs in SWTableViewCell
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
    BOOL isEnteringEditingMode = (state == kCellStateRight);
    [self animateEnteringEditingMode:isEnteringEditingMode];
}

- (void)animateEnteringEditingMode:(BOOL)isEditing {
    __weak typeof(self) weakSelf = self;
    CGFloat animationDuration = 0.3f;
    
    if (!isEditing) {
        [self.navigationItem setRightBarButtonItem:self.composeBarButtonItem animated:YES];
        [self.navigationItem setLeftBarButtonItem:self.settingsBarButtonItem animated:YES];
        
        [UIView animateWithDuration:animationDuration animations:^{
            weakSelf.searchBarCoverView.alpha = 0;
        } completion:^(BOOL finished) {
            weakSelf.searchBarCoverView.alpha = 0;
            weakSelf.searchBar.userInteractionEnabled = YES;
        }];
    } else {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        
        [UIView animateWithDuration:animationDuration animations:^{
            weakSelf.searchBarCoverView.alpha = 0.3;
        } completion:^(BOOL finished) {
            weakSelf.searchBarCoverView.alpha = 0.3;
            weakSelf.searchBar.userInteractionEnabled = NO;
        }];
    }
}

@end
