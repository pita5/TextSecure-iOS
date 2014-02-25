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
#import "TSProtocols.h"
@class TSMessage;
@class TSThread;
@class TSAttachment;

@interface ComposeMessageViewController : JSMessagesViewController <UIImagePickerControllerDelegate,UIActionSheetDelegate,UITextViewDelegate, JSMessagesViewDelegate, JSMessagesViewDataSource>


- (instancetype)initWithConversation:(TSThread*)thread;

-(void) reloadModel:(NSNotification*)notification ;

@property (nonatomic, retain) TSContact *contact;
@property (nonatomic) TSThread *thread;
@property (nonatomic, strong) TSAttachment *attachment;
@property (nonatomic) TSWhisperMessageType messagingType;

@end

