//
//  ViewController.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "SMSViewController.h"
#import "Message.h"
@implementation SMSViewController
- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Messages";
}

-(void) reloadModel:(NSNotification*)notification {
  self.messages=[self.messagesDB getMessages];
  [self.tableView reloadData];
}


// for custom designed cells
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  // for custom designed cells
 	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"TextSecureSMS"];
  UILabel *phoneNumberLabel = (UILabel *)[cell viewWithTag:1];
  UILabel *previewLabel = (UILabel *)[cell viewWithTag:2];
  UILabel *dateLabel = (UILabel *)[cell viewWithTag:3];
  
  Message* message = [self.messages objectAtIndex:indexPath.row];
  phoneNumberLabel.text = [message.destinations objectAtIndex:0];
  previewLabel.text = message.text;
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"HH:mm"];
  NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
  dateLabel.text = dateString;
  
  return cell;
}

@end
