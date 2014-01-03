//
//  TSAttachment.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/2/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSAttachment.h"
#import <UIImage-Categories/UIImage+Resize.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFNetworking.h>

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

-(NSString*) getMIMEContentType {
  switch (self.attachmentType) {
    case TSAttachmentEmpty:
      return @"";
      break;
    case TSAttachmentPhoto:
      return @"image/png";
      break;
    case TSAttachmentVideo:
      return @"video/mp4";
    default:
      return @"";
      break;
  }
}

-(BOOL) readyForUpload {
  return (self.attachmentType != TSAttachmentEmpty && self.attachmentId != nil && self.attachmentURL != nil);
}

- (void)testUpload {
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setHTTPMethod:@"PUT"];
  [request setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
  [request setHTTPBody:self.attachmentData];
  [request setValue:[NSString stringWithFormat:@"%d", [self.attachmentData length]] forHTTPHeaderField:@"Content-Length"];
  [request setValue:@"public-read" forHTTPHeaderField:@"x-amz-acl"];
  [request setValue:@"iPhone-OS/7.0 en EN" forHTTPHeaderField:@"User-Agent"];
  [request setURL:self.attachmentURL];
  NSHTTPURLResponse * response = nil;
  NSError * error = nil;
  NSData * data = [NSURLConnection sendSynchronousRequest:request
                                        returningResponse:&response
                                                    error:&error];
  
  NSLog(@"response %d",[response statusCode]);
  

  
  
}
@end
