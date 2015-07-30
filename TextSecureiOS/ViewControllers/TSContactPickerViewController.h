//
//  TSContactPickerViewController.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 02/02/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSContactPickerViewController : UITableViewController

@property (nonatomic, strong) IBOutlet UIBarButtonItem *nextButton;
@property (nonatomic) BOOL allowMultipleSelections;
-(IBAction) next;
@end
