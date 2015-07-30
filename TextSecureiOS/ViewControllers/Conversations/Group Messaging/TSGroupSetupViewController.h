//
//  TSGroupSetupViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/8/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSGroup.h"


@interface TSGroupSetupViewController : UIViewController <UIImagePickerControllerDelegate,UIActionSheetDelegate,UITextFieldDelegate, UINavigationControllerDelegate>
@property(nonatomic,strong) IBOutlet UITextField *groupName;
@property(nonatomic,strong) IBOutlet UIButton *groupPhoto;
@property(nonatomic,strong) IBOutlet UIBarButtonItem *nextButton;
@property(nonatomic,strong) NSArray* whisperContacts;
@property(nonatomic,strong) TSGroup* group;
- (IBAction) setGroupPhotoPressed:(UIButton *)sender;
-(IBAction)createNonBroadcastGroup:(id)sender;
-(IBAction)createBroadcastGroup:(id)sender;
-(void)createGroup;
@end
