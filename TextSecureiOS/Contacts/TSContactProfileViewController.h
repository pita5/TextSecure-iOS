//
//  TSContactProfileViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 5/18/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TSContact;
@interface TSContactProfileViewController : UIViewController
@property (nonatomic,retain) TSContact* contact;
@end
