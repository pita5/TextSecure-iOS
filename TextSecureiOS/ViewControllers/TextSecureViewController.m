//
//  TextSecureViewController.m
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
#import "TSContactManager.h"
#import "TSContact.h"
#import "TSMessage.h"
#import "TSMessageViewController.h"
#import "TSMessageConversationCell.h"
#import "PasswordUnlockViewController.h"
#import "TSStorageMasterKey.h"
#import "TSContactPickerViewController.h"
#import "TSConversation.h"
#import "TSGroupSetupViewController.h"
#import "TSSetMasterPasswordViewController.h"

static NSString *kCellIdentifier = @"CellIdentifier";

static NSString *kThreadTitleKey = @"kThreadTitleKey";
static NSString *kThreadDateKey = @"kThreadDateKey";
static NSString *kThreadMessageKey = @"kThreadMessageKey";
static NSString *kThreadImageKey = @"kThreadImageKey";

@interface TextSecureViewController() <SWTableViewCellDelegate>

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *settingsBarButtonItem;
//@property (nonatomic, strong) UIView *searchBarCoverView;
@property (nonatomic, strong) NSArray *conversations;

@end

@implementation TextSecureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Messages";
    self.navigationController.navigationBarHidden = NO;

#warning   // FETCH CONVERSATIONS WITH COMPLETION BLOCK
    
    UIEdgeInsets inset = UIEdgeInsetsMake(44, 0, 0, 0);
    self.tableView.contentInset = inset;
    [self.tableView registerClass:[TSMessageConversationCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor lightGrayColor];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kDBNewMessageNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Refreshing");
            self.conversations = [TSMessagesDatabase conversations];
            [self.tableView reloadData];
        });
    }];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.conversations = [TSMessagesDatabase conversations];
    [self.tableView reloadData];
    
    self.navigationController.navigationBarHidden = NO;
    
    if([TSKeyManager hasVerifiedPhoneNumber] && [TSMessagesDatabase databaseWasCreated] && [TSStorageMasterKey isStorageMasterKeyLocked]) {
        
        // check if user decided to skip password protection
        BOOL passwordNotSet = [[NSUserDefaults standardUserDefaults] boolForKey:kPasswordNotSet];
        if (passwordNotSet) {
            
            NSError *error = nil;
            [TSStorageMasterKey unlockStorageMasterKeyUsingPassword:@"" error:&error];
            BOOL stillLocked = [TSStorageMasterKey isStorageMasterKeyLocked];
            
            if (stillLocked) {
                [self performSegueWithIdentifier:@"PasswordUnlockSegue" sender:self];
            }
            
        } else {
             [self performSegueWithIdentifier:@"PasswordUnlockSegue" sender:self];
        }
        
    } else if([TSKeyManager hasVerifiedPhoneNumber] == NO) {
        [self performSegueWithIdentifier:@"ObtainVerificationCode" sender:self];
    }
}

- (IBAction)composeMessage {
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[[TSContactPickerViewController alloc]initWithNibName:nil bundle:nil]] animated:YES completion:nil];
}


#pragma mark - UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
 	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if ([cell isKindOfClass:[TSMessageConversationCell class]]) {
        
        TSConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
        TSMessageConversationCell *threadCell = (TSMessageConversationCell *)cell;
        threadCell.titleLabel.text = [conversation.contact name];
        threadCell.timestampLabel.text = [dateFormatter stringFromDate:conversation.lastMessageDate];
        threadCell.conversationPreviewLabel.text = [conversation lastMessage];
        
        UIImage *disclosureIndicatorImage = [[UIImage imageNamed:@"disclosure_indicator"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        threadCell.disclosureImageView.image = disclosureIndicatorImage;
        
        NSMutableArray *rightUtilityButtons = [[NSMutableArray alloc] init];
        UIColor *deleteButtonColor = [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f];
        [rightUtilityButtons sw_addUtilityButtonWithColor:deleteButtonColor title:@"Delete"];
        
        threadCell.rightUtilityButtons = rightUtilityButtons;
        threadCell.delegate = self;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section{
    if([TSMessagesDatabase databaseWasCreated]) {
        // don't display until db is unlocked (we have "dummy data" right now, but this better mimics UX behavior)
        return [self.conversations count];
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
        // Delete row
        [self Edit:self];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		[self Edit:self];
	}
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self performSegueWithIdentifier:@"NewMessageOnThreadSegue" sender:self];
}


-(void) reloadModel:(NSNotification*)notification {
    [self.tableView reloadData];
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

- (void)swipeableTableViewCell:(TSMessageConversationCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index{
    
    dataBaseUpdateCompletionBlock block = ^(BOOL success) {
        if (success) {
            NSMutableArray *removalArray = [self.conversations mutableCopy];
            [removalArray removeObjectAtIndex:index];
            self.conversations = [removalArray copy];
            [self swipeableTableViewCell:cell scrollingToState:kCellStateCenter];
            [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else{
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"An unexpected error occured" message:@"An error occured while trying to delete that message. Please try again and if it persists, please report it." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    };
#ifdef DEBUG
    [TSMessagesDatabase deleteMessagesAndSessionsForConversation:[self.conversations objectAtIndex:index] completion:block];
#else
    [TSMessagesDatabase deleteMessagesForConversation:[self.conversations objectAtIndex:index] completion:block];
#endif
    
    
}

// This SWTableViewCell delegate method is still buggy and doesn't represent the exact state of the cell,
// e.g. when the right utility buttons are not set.
// TODO: Fix bugs in SWTableViewCell
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
    BOOL isEnteringEditingMode = (state == kCellStateRight);
    [self animateEnteringEditingMode:isEnteringEditingMode];
}

- (void)animateEnteringEditingMode:(BOOL)isEditing {
    if (!isEditing) {
        self.composeBarButtonItem.enabled = YES;
    } else {
        self.composeBarButtonItem.enabled = NO;
    }
}


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"NewMessageOnThreadSegue"]) {
        TSMessageViewController *mvc = [segue destinationViewController];
        //        [vc setupWithConversation:[TSThread threadWithContacts:[(TSGroupSetupViewController*)sender whisperContacts] save:YES]];
        if([sender respondsToSelector:@selector(group)]) {
            mvc.group = [sender performSelector:@selector(group)];
        }
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        TSConversation* conversation = [self.conversations objectAtIndex:selectedIndexPath.row];
        mvc.contact=conversation.contact;
    }

}


@end
