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

- (void)uploadTest {
  NSURL *url = [NSURL URLWithString:@"https://xxx.s3-ap-northeast-1.amazonaws.com/"];
  AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
  NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"194-note-2.png"]);
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"xxxxx/videos/XXXXW",@"key",
                          @"XXXXXXXX",@"AWSAccessKeyId",
                          
                          @"XXXXXXXXXXXXXXXXXXXXXXXXXXXXX",@"policy",
                          @"XXXXXXXXXXXXXXXXXXXXXXXXX",@"signature",
                          
                          nil];
  
  
  NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/" parameters:params constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
    [formData appendPartWithFileData:imageData name:@"file" fileName:@"194-note-2.png" mimeType:@"image/png"];
  }];
  
  AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
  [operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
    NSLog(@"Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
  }];
  [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *theOperation, id responseObject) {
    NSLog(@"Success:%@,%@",operation.response.allHeaderFields, operation.responseString);
    
    
    
  } failure:^(AFHTTPRequestOperation *theOperation, NSError *error) {
    NSLog(@"Error:%@ ,%@,%@",error,operation.response.allHeaderFields,operation.responseString);
  }];
  [operation start];
  
  
}
@end
