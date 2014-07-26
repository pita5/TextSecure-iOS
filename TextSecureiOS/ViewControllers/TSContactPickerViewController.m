//
//  TSContactPickerViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 02/02/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSContactPickerViewController.h"
#import "TSContactManager.h"
#import "TSMessageViewController.h"
#import "TSContact.h"
#import "TSGroupSetupViewController.h"
#import "TSMessagesDatabase.h"
#define tableViewCellsDequeID @"TSContactCell"
@interface TSContactPickerViewController ()

@property NSArray *whisperContacts;

@end

@implementation TSContactPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.nextButton.enabled = YES;
    self.nextButton.title = @"Group";
    self.allowMultipleSelections = NO;
    [self refreshContacts];
}

- (void)refreshContacts
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.title = @"Loading";

    [TSContactManager getAllContactsIDs:^(NSArray *contacts) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:FALSE];
        if(self.allowMultipleSelections) {
            self.title = @"Pick recipients";
        }
        else {
            self.title = @"Pick recipient";
        }
        self.whisperContacts = contacts;
        [self.tableView reloadData];
    }];
}

#pragma mark Tableview Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.whisperContacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:tableViewCellsDequeID];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:tableViewCellsDequeID];
    }

    TSContact *contact = ((TSContact *)[self.whisperContacts objectAtIndex:indexPath.row]);
    cell.textLabel.text = contact.name;
    cell.detailTextLabel.text = [contact labelForRegisteredNumber];
    if([[self.whisperContacts objectAtIndex:indexPath.row] isSelected]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [[self.whisperContacts objectAtIndex:indexPath.row] reverseIsSelected];
    if(!self.allowMultipleSelections) {
        self.whisperContacts=[self getSelectedContacts];
        [self performSegueWithIdentifier:@"ComposeMessageSegue" sender:self];
    }
    else {
        [self.tableView reloadData];
    }

}

-(NSArray*) getSelectedContacts {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isSelected = TRUE"];
    return [self.whisperContacts filteredArrayUsingPredicate:pred];
}

-(IBAction) next {
    if(self.allowMultipleSelections)  {
        self.whisperContacts=[self getSelectedContacts];
        [self performSegueWithIdentifier:@"TSGroupSetupSegue" sender:self];
    }
    else {
        self.nextButton.title = @"Create";
        self.allowMultipleSelections = YES;
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"TSGroupSetupSegue"]) {        
        TSGroupSetupViewController *vc = [segue destinationViewController];
        vc.whisperContacts = [self getSelectedContacts];
    } else if ([segue.destinationViewController isKindOfClass:[TSMessageViewController class]]) {
        TSMessageViewController *vc = segue.destinationViewController;
        if(![TSMessagesDatabase contactForRegisteredID:self.whisperContacts.firstObject]) {
            [TSMessagesDatabase storeContact:self.whisperContacts.firstObject];
        }
        vc.contact = self.whisperContacts.firstObject;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
