//
//  ViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "ThreadViewController.h"
@implementation ThreadViewController


- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Conversation";
}

-(void) reloadModel:(NSNotification*)notification {
  // TODO: make this be threads
  self.messages=[self.messagesDB getMessages];
  [self.tableView reloadData];
}






// for custom designed cells
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // for custom designed cells
  // TODO: actually figure out if message was sent or recieved
  Message* message = [self.messages objectAtIndex:indexPath.row];
  UITableViewCell *cell;
  if(indexPath.row %2 == 0) {
    cell = [tv dequeueReusableCellWithIdentifier:@"TextSecureThreadSent"];
  }
  else {
    cell = [tv dequeueReusableCellWithIdentifier:@"TextSecureThreadReceived"];
  }
  UILabel *messageLabel = (UILabel *)[cell viewWithTag:1];
  UILabel *dateLabel = (UILabel *)[cell viewWithTag:2];
  messageLabel.text = message.text;
  [messageLabel setFont:[UIFont fontWithName:@"OpenSans" size:12]];
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"HH:mm"];
  NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
  dateLabel.text = dateString;
  [dateLabel setFont:[UIFont fontWithName:@"OpenSans" size:12]];
  return cell;
}




@end
