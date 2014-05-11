//
//  TSPresentIdentityQRCodeViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/30/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSPresentIdentityQRCodeViewController : UIViewController
@property(nonatomic,strong) IBOutlet UIImageView* qrCodeView;
@property(nonatomic,strong) NSData* identityKey;
@end
