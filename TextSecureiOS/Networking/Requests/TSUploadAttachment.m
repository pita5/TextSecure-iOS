//
//  TSUploadAttachment.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/3/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSUploadAttachment.h"
#import "TSAttachment.h"
#import <AFNetworking/AFHTTPRequestOperation.h>
@implementation TSUploadAttachment

-(TSRequest*) initWithAttachment:(TSAttachment*) attachment{
  
  self = [super initWithURL:attachment.attachmentURL];
  self.HTTPMethod = @"PUT";
  self.attachment = attachment;
    
  [self setHTTPBody:[self.attachment getData]];
  [self setAllHTTPHeaderFields: @{@"Content-Type": @"application/octet-stream"}];

  return self;
  
}



-(void) uploadAttachment {
  
  NSDictionary *headersDict = @{@"Content-Type": @"application/octet-stream"};
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL];
  [request setHTTPMethod:@"PUT"];
  [request setHTTPBody:[self.attachment getData]];
  [request setAllHTTPHeaderFields:headersDict];
  
  AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
  [operation  setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    // if everything run great, we have to invalidate timer to notify
    NSLog(@"upload with success code %d",operation.response.statusCode);
    
  }
  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"error: %@",  error);
  }];


  
  [operation start];
  
  
  
}




@end
