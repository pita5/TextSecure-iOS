//
//  TSVerifyIdentityViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSContact.h"
@interface TSVerifyIdentityViewController : UIViewController

@property (nonatomic,strong) IBOutlet UILabel *theirIdentity;
@property (nonatomic,strong) IBOutlet UILabel *myIdentity;
@property (nonatomic,strong) TSContact* contact;
@end
