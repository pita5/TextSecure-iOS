//
//  TSUploadAttachment.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/3/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSUploadAttachment.h"

@implementation TSUploadAttachment

-(TSRequest*) initWithAttachment:(NSData*) attachment uploadLocation:(NSString*)uploadLocation{
  
  self = [super initWithURL:[NSURL URLWithString:uploadLocation]];
  self.HTTPMethod = @"PUT";
  return self;
  
}


@end
