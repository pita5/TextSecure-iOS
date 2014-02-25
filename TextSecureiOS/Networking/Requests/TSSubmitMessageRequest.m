//
//  TSSubmitMessageRequest.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 11/30/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSSubmitMessageRequest.h"
#import "TSContact.h"
#import "TSProtocols.h"
@implementation TSSubmitMessageRequest

-(TSRequest*) initWithRecipient:(NSString*) contactRegisteredID message:(NSString*) messageBody ofType:(TSWhisperMessageType)type {
  NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc]
                                            initWithObjects:[[NSArray alloc]
                                                             initWithObjects:[NSNumber numberWithInt:type],
                                                             contactRegisteredID,
                                                             messageBody,
                                                             [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]],
                                                             nil]
                                            forKeys:[[NSArray alloc] initWithObjects:@"type",@"destination",@"body",@"timestamp" ,nil]];


  self = [super initWithURL:[NSURL URLWithString:textSecureMessagesAPI]];
  NSMutableDictionary *allMessages = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[NSArray alloc] initWithObjects: messageDictionary,nil],@"messages", nil];
  [self setHTTPMethod:@"POST"];
  [self setParameters:allMessages];
  return self;
}

@end
