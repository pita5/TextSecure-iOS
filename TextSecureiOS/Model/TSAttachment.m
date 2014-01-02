//
//  TSAttachment.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/2/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSAttachment.h"

@implementation TSAttachment

-(id) initWithAttachmentData:(NSData*) data  withType:(TSAttachmentType)type {
  if(self=[super init]) {
    self.attachmentData = data;
    self.attachmentType = type;
  }
  return self;
}

@end
