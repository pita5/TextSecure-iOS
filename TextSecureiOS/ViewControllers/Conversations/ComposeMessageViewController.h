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

@interface ComposeMessageViewController : JSMessagesViewController <TITokenFieldDelegate, UITextViewDelegate, JSMessagesViewDelegate, JSMessagesViewDataSource>

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableArray *timestamps;

// Need to be initialized with one of those methods

- (id) initWithConversationID:(NSString*)contactID;
- (id) initNewConversation;

@end

