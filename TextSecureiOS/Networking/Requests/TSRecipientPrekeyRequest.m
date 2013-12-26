//
//  TSGetRecipientPrekey.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 11/30/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRecipientPrekeyRequest.h"
#import "TSContact.h"
@implementation TSRecipientPrekeyRequest

-(TSRequest*) initWithRecipient:(TSContact*) contact {
  NSString* recipientInformation;
  if([contact.relay length]){
    recipientInformation = [NSString stringWithFormat:@"%@?%@",contact.registeredID,contact.relay];
  }
  else {
    recipientInformation=contact.registeredID;
  }
  self = [super initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", textSecureKeysAPI, recipientInformation]]];
    
  [self setHTTPMethod:@"GET"];
  
  return self;
}

@end
