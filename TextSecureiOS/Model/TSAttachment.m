//
//  TSAttachment.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/2/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSAttachment.h"
#import <UIImage-Categories/UIImage+Resize.h>

@implementation TSAttachment

-(id) initWithAttachmentData:(NSData*) data  withType:(TSAttachmentType)type withThumbnailImage:(UIImage*)thumbnail {
  if(self=[super init]) {
    self.attachmentData = data;
    self.attachmentType = type;
    self.attachmentThumbnail=thumbnail;
  }
  return self;
}


-(UIImage*) getThumbnailOfSize:(int)size {
  return  [self.attachmentThumbnail thumbnailImage:size transparentBorder:0 cornerRadius:3.0 interpolationQuality:0];
}

@end
