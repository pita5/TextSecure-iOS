//
//  TSMessageThreadCell.h
//  TextSecureiOS
//
//  Created by Claudiu-Vlad Ursache on 26/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TSMessageThreadCell : UITableViewCell

@property(nonatomic, readwrite, strong) UILabel *titleLabel;
@property(nonatomic, readwrite, strong) UILabel *timestampLabel;
@property(nonatomic, readwrite, strong) UILabel *threadPreviewLabel;
@property(nonatomic, readwrite, strong) UIImageView *disclosureImageView;

@end
