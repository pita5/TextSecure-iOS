//
//  ComposeMessageViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/30/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TITokenField.h"
#import "JSMessagesViewController.h"
#import "TSContact.h"

@class TSMessage;
@class TSThread;
@interface ComposeMessageViewController : JSMessagesViewController <TITokenFieldDelegate, UITextViewDelegate, JSMessagesViewDelegate, JSMessagesViewDataSource>

@property (nonatomic, retain) TSContact *contact;
@property (nonatomic) TSThread *thread;
// Need to be initialized with one of those methods

- (instancetype)initWithConversationID:(NSString*)contactID;
- (instancetype)initNewConversation;


-(void) messageSent:(TSMessage*) message;
-(void) messageRecieved;
-(void)addMessage:(TSMessage*)message;
@end

