//
//  TSMessageThreadCell.m
//  TextSecureiOS
//
//  Created by Claudiu-Vlad Ursache on 26/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessageThreadCell.h"

@implementation TSMessageThreadCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;

    self.opaque = YES;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    self.titleLabel = titleLabel;
    
    UILabel *timestampLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    timestampLabel.textColor = [UIColor lightGrayColor];
    timestampLabel.font = [UIFont systemFontOfSize:12.0f];
    self.timestampLabel = timestampLabel;
    
    UILabel *threadPreviewLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    threadPreviewLabel.textColor = [UIColor lightGrayColor];
    threadPreviewLabel.numberOfLines = 2;
    threadPreviewLabel.font = [UIFont systemFontOfSize:13.0f];
    self.threadPreviewLabel = threadPreviewLabel;
        
    UIImageView *disclosureImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    disclosureImageView.tintColor = [UIColor lightGrayColor];
    self.disclosureImageView = disclosureImageView;
    
    UIImageView *threadImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.threadImageView = threadImageView;
    
    [self.contentView addSubview:self.threadImageView];
    [self.contentView addSubview:self.timestampLabel];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.disclosureImageView];
    [self.contentView addSubview:self.threadPreviewLabel];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect contentViewBounds = self.contentView.bounds;
    
    CGFloat yPadding = 5.0f;
    CGFloat topElementHeight = 25.0f;
    
    CGSize threadImageViewSize = CGSizeMake(CGRectGetHeight(contentViewBounds), CGRectGetHeight(contentViewBounds));
    self.threadImageView.frame = CGRectMake(yPadding, yPadding, threadImageViewSize.width - 2*yPadding, threadImageViewSize.height - 2*yPadding);
    
    CGFloat threadImagePadding = 2*yPadding + CGRectGetWidth(self.threadImageView.frame);
    
    CGSize disclosureImageViewSize = CGSizeMake(topElementHeight, topElementHeight);
    self.disclosureImageView.frame = CGRectMake(CGRectGetWidth(contentViewBounds) - disclosureImageViewSize.width, yPadding, disclosureImageViewSize.width, disclosureImageViewSize.height);
    
    CGSize timestampLabelSize = CGSizeMake(60, topElementHeight);
    self.timestampLabel.frame = CGRectMake(CGRectGetWidth(contentViewBounds) - timestampLabelSize.width - disclosureImageViewSize.width, yPadding, timestampLabelSize.width, timestampLabelSize.height);
    
    CGSize titleLabelSize = CGSizeMake(CGRectGetWidth(contentViewBounds) - threadImagePadding - disclosureImageViewSize.width - timestampLabelSize.width, topElementHeight);
    self.titleLabel.frame = CGRectMake(threadImagePadding, yPadding, titleLabelSize.width, titleLabelSize.height);
    
    CGFloat rightPadding = 10.0f;
    CGSize threadPreviewLabelSize = CGSizeMake(CGRectGetWidth(contentViewBounds), CGRectGetHeight(contentViewBounds) - 2*yPadding - CGRectGetHeight(self.titleLabel.frame));
    self.threadPreviewLabel.frame = CGRectMake(threadImagePadding, CGRectGetMaxY(self.titleLabel.frame), threadPreviewLabelSize.width - threadImagePadding - rightPadding, threadPreviewLabelSize.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
