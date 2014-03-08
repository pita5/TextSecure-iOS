//
//  TSGroupSetupViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/8/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSGroupSetupViewController : UIViewController<UIImagePickerControllerDelegate,UIActionSheetDelegate,UITextFieldDelegate>
@property(nonatomic,strong) IBOutlet UITextField *groupName;
@property(nonatomic,strong) IBOutlet UIButton *groupPhoto;
@property(nonatomic,strong) NSArray* groupContacts;
- (IBAction) setGroupPhotoPressed:(UIButton *)sender;
@end
