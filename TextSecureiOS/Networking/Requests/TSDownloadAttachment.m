//
//  TSDownloadAttachment.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSDownloadAttachment.h"
#import "TSAttachment.h"
@implementation TSDownloadAttachment

-(TSRequest*) initWithAttachment:(TSAttachment*) attachment{
  
  self = [super initWithURL:attachment.attachmentURL];
  self.HTTPMethod = @"GET";
  self.attachment = attachment;
  
  [self setAllHTTPHeaderFields: @{@"Content-Type": @"application/octet-stream"}];
  
  return self;
  
}

@end
