//
//  ComposeMessageViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/30/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSMessagesViewController.h"
#import "TSContact.h"
@class TSGroup;
@class TSMessage;
@class TSAttachment;

/**
 *  ComposeMessageViewController has two constructors, one for 1-to-1 discussions and the other one for group discussions.
 */

@interface TSMessageViewController : JSMessagesViewController <UIImagePickerControllerDelegate,UIActionSheetDelegate,UITextViewDelegate, JSMessagesViewDelegate, JSMessagesViewDataSource, UINavigationControllerDelegate>

/**
 *  Constructor for 1-to-1 discussions
 *
 *  @param contact Contact to have discussion with
 *
 *  @return A viewcontroller for displaying discussions
 */

- (instancetype)initWithConversation:(TSContact*)contact;

@property (nonatomic, retain) TSContact *contact;
@property (nonatomic, retain) TSGroup *group;
@property (nonatomic) TSWhisperMessageType messagingType;

@end

