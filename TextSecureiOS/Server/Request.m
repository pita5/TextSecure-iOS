//
//  Request.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/29/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "Request.h"

@implementation Request
@synthesize httpRequestType;
@synthesize httpRequestURL;
@synthesize httpRequestData;
@synthesize apiRequestType;
-(id) initWithHttpRequestType:(int)hpRequestType requestUrl:(NSURL*)requestUrl requestData:(NSData*)requestData apiRequestType:(int)aiRequestType;{
  self = [super init];
  if (self) {
    self.httpRequestURL=requestUrl;
    self.httpRequestType=hpRequestType;
    self.httpRequestData=requestData;
    self.apiRequestType=aiRequestType;
  }
  return self;
}
@end
