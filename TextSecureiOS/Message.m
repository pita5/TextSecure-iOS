//
//  Message.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/28/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "Message.h"

@implementation Message

@synthesize source;
@synthesize destinations;
@synthesize text;
@synthesize attachments;
@synthesize timestamp;

-(id)initWithText:(NSString*)messageText messageSource:(NSString*) messageSource messageDestinations:(NSArray*)messageDestinations  messageAttachments:(NSArray*) messageAttachments messageTimestamp:(NSDate*)messageTimestamp{
  self = [super init];
  if (self) {
    self.source = messageSource;
    self.destinations = messageDestinations;
    self.text = messageText;
    self.attachments = messageAttachments;
    self.timestamp =messageTimestamp;
  }
  return self;
}

@end
