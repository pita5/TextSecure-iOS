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
#import "TSSettingsViewController.h"
#import "TSContactManager.h"
#import "TSContact.h"
#import "TSMessage.h"
#import "TSMessageViewController.h"
#import "TSMessageConversationCell.h"
#import "PasswordUnlockViewController.h"
#import "TSStorageMasterKey.h"
#import "TSContactPickerViewController.h"
#import "TSConversation.h"

static NSString *kCellIdentifier = @"CellIdentifier";

static NSString *kThreadTitleKey = @"kThreadTitleKey";
static NSString *kThreadDateKey = @"kThreadDateKey";
static NSString *kThreadMessageKey = @"kThreadMessageKey";
static NSString *kThreadImageKey = @"kThreadImageKey";

@interface TextSecureViewController() <SWTableViewCellDelegate>
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *composeBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *settingsBarButtonItem;
//@property (nonatomic, strong) UIView *searchBarCoverView;
@property (nonatomic, strong) NSArray *conversations;
@end

@implementation TextSecureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Messages";
    
#warning   // FETCH CONVERSATIONS WITH COMPLETION BLOCK
    
    UIEdgeInsets inset = UIEdgeInsetsMake(44, 0, 0, 0);
    self.tableView.contentInset = inset;
    
    self.settingsBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(openSettings)];
    self.navigationItem.leftBarButtonItem = self.settingsBarButtonItem;
    
    self.composeBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeMessage)];
    self.navigationItem.rightBarButtonItem = self.composeBarButtonItem;
    
    [self.tableView registerClass:[TSMessageConversationCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor lightGrayColor];
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    
    if([TSKeyManager hasVerifiedPhoneNumber] && [TSMessagesDatabase databaseWasCreated] && [TSStorageMasterKey isStorageMasterKeyLocked]) {
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UIViewController *passwordUnlockViewController = [storyboard instantiateViewControllerWithIdentifier:@"PasswordUnlockViewController"];
        [self presentViewController:passwordUnlockViewController animated:NO completion:nil];
        
    } else if([TSKeyManager hasVerifiedPhoneNumber] == NO) {
        [self performSegueWithIdentifier:@"ObtainVerificationCode" sender:self];
    }
}

- (void)composeMessage {
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:[[TSContactPickerViewController alloc]initWithNibName:nil bundle:nil]] animated:YES completion:nil];
}

- (void)openSettings {
    [self performSegueWithIdentifier:@"openSettings" sender:self];
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
        threadCell.containingTableView = tv;
        threadCell.cellHeight = [self tableView:tv heightForRowAtIndexPath:indexPath];
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
        [self Edit:self];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
		[self Edit:self];
	}
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TSConversation* conversation = [self.conversations objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:[[TSMessageViewController alloc] initWithConversation:conversation.contact] animated:YES];
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

#warning currently not supported
    
    //    [TSMessagesDatabase deleteThread:[self.conversations objectAtIndex:index] withCompletionBlock:^(BOOL success) {
//        [self swipeableTableViewCell:cell scrollingToState:kCellStateCenter];
//        [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationAutomatic];
//    }];
}

// This SWTableViewCell delegate method is still buggy and doesn't represent the exact state of the cell,
// e.g. when the right utility buttons are not set.
// TODO: Fix bugs in SWTableViewCell
- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state {
    BOOL isEnteringEditingMode = (state == kCellStateRight);
    [self animateEnteringEditingMode:isEnteringEditingMode];
}

- (void)animateEnteringEditingMode:(BOOL)isEditing {
    //    __weak typeof(self) weakSelf = self;
    //    CGFloat animationDuration = 0.3f;
    
    if (!isEditing) {
        
        [self.navigationItem setRightBarButtonItem:self.composeBarButtonItem animated:YES];
        [self.navigationItem setLeftBarButtonItem:self.settingsBarButtonItem animated:YES];
        
    } else {
        
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    
    }
}

@end
