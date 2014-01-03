//
//  TSUploadAttachment.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/3/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSUploadAttachment.h"
#import "TSAttachment.h"
@implementation TSUploadAttachment

-(TSRequest*) initWithAttachment:(TSAttachment*) attachment{
  
  self = [super initWithURL:attachment.attachmentURL];
  self.HTTPMethod = @"PUT";
  return self;
  
}


@end
