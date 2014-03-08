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
#import "ComposeMessageViewController.h"
#import "TSMessageThreadCell.h"
#import "PasswordUnlockViewController.h"
#import "TSStorageMasterKey.h"
#import "TSThread.h"
#import "TSContactPickerViewController.h"

static NSString *kCellIdentifier = @"CellIdentifier";

static NSString *kThreadTitleKey = @"kThreadTitleKey";
static NSString *kThreadDateKey = @"kThreadDateKey";
static NSString *kThreadMessageKey = @"kThreadMessageKey";
static NSString *kThreadImageKey = @"kThreadImageKey";

@interface TextSecureViewController() <SWTableViewCellDelegate>
@property (nonatomic, strong) NSArray *threads;
@end

@implementation TextSecureViewController

- (void)viewDidLoad {
    self.threads = @[];
    [super viewDidLoad];
    
    self.threads = [TSMessagesDatabase threads];
    self.navigationController.navigationBarHidden = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadModel:) name:TSDatabaseDidUpdateNotification object:nil];
    
    
    [self.tableView registerClass:[TSMessageThreadCell class] forCellReuseIdentifier:kCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor lightGrayColor];
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    
    if([TSKeyManager hasVerifiedPhoneNumber] && [TSMessagesDatabase databaseWasCreated] && [TSStorageMasterKey isStorageMasterKeyLocked]) {
        [self performSegueWithIdentifier:@"PasswordUnlockSegue" sender:self];
        
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
    
    if ([cell isKindOfClass:[TSMessageThreadCell class]]) {
        
        TSThread* thread = [self.threads objectAtIndex:indexPath.row];
        TSMessageThreadCell *threadCell = (TSMessageThreadCell *)cell;
        threadCell.thread = thread;
        threadCell.titleLabel.text =thread.latestMessage.senderId;
        threadCell.timestampLabel.text = [dateFormatter stringFromDate:thread.latestMessage.timestamp];
        threadCell.threadPreviewLabel.text = thread.latestMessage.content;
        
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
        return [_threads count];
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
    TSThread* thread = [self.threads objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:[[ComposeMessageViewController alloc] initWithConversation:thread] animated:YES];
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

- (void)swipeableTableViewCell:(TSMessageThreadCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index{
    [TSMessagesDatabase deleteThread:[self.threads objectAtIndex:index] withCompletionBlock:^(BOOL success) {
        [self swipeableTableViewCell:cell scrollingToState:kCellStateCenter];
        [self.tableView deleteRowsAtIndexPaths:@[[self.tableView indexPathForCell:cell]] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    }];
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
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        [self.navigationItem.leftBarButtonItem setEnabled:YES];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationItem.leftBarButtonItem setEnabled:NO];

        
    }
}

@end
