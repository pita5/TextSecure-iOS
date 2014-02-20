//
//  TSMessageThreadCell.h
//  TextSecureiOS
//
//  Created by Claudiu-Vlad Ursache on 26/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <SWTableViewCell.h>
#import "TSThread.h"

@interface TSMessageThreadCell : SWTableViewCell

@property(nonatomic, readwrite, strong) UILabel *titleLabel;
@property(nonatomic, readwrite, strong) UILabel *timestampLabel;
@property(nonatomic, readwrite, strong) UILabel *threadPreviewLabel;
@property(nonatomic, readwrite, strong) UIImageView *disclosureImageView;

@property(nonatomic, retain) TSThread *thread;

@end
