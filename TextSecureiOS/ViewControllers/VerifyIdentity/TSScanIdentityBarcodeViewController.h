//
//  TSScanIdentityBarcodeViewController.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface TSScanIdentityBarcodeViewController : UIViewController<AVCaptureMetadataOutputObjectsDelegate>

@property(nonatomic,strong) AVCaptureSession *session;
@property(nonatomic,strong) AVCaptureDevice *device;
@property(nonatomic,strong) AVCaptureDeviceInput *input;
@property(nonatomic,strong) AVCaptureMetadataOutput *output;
@property(nonatomic,strong) AVCaptureVideoPreviewLayer *prevLayer;

@property(nonatomic,strong) UIView *highlightView;
@property(nonatomic,strong) UILabel *label;
@property(nonatomic,strong) NSData *identityKey;
@end
