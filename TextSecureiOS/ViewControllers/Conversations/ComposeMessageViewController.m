//
//  ComposeMessageViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/30/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "ComposeMessageViewController.h"
#import "TSMessagesManager.h"
#import "TSContactManager.h"
#import "TSContact.h"
#import "TSMessagesDatabase.h"
#import "TSMessage.h"
#import "TSThread.h"
#import "TSKeyManager.h"
#import "TSAttachment.h"
#import "TSAttachmentManager.h"
#import "Cryptography.h"
#import "FilePath.h"

@interface ComposeMessageViewController ()
@property (nonatomic, retain) NSArray *contacts;
@end

@implementation ComposeMessageViewController {
	CGFloat _keyboardHeight;
}

- (id) initWithConversation:(TSThread*)thread {
#warning this isn't supporting group messaging yet, obviously
    self = [super initWithNibName:nil bundle:nil];
    
    if (!self) return nil;
    
    self.thread = thread;
    
    [self setupThread];
    
    return self;
}

-(void) setupThread  {
#warning hack we will want to change when we support more than one contact
    NSString* myUsername = [TSKeyManager getUsernameToken];
    for(TSContact* contact in self.thread.participants.array) {
        self.title = contact.registeredID;
        self.contact = contact;
        if(![contact.registeredID isEqualToString:myUsername] ){
            // handles edge case where I'm writing myself
            break;
        }
    }
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)]; //scrolls to bottom
}

- (void) dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadModel:) name:TSDatabaseDidUpdateNotification object:nil];
    self.delegate = self;
    self.dataSource = self;
    self.inputToolBarView.textView.delegate = self;
	[self.view setBackgroundColor:[UIColor whiteColor]];
    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.view.frame.size.height - 44);
}

- (UIButton *)sendButton {
    // Override to use a custom send button
    // The button's frame is set automatically for you
    return [UIButton defaultSendButton];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[TSMessagesDatabase getMessagesOnThread:self.thread] count];
}

#pragma mark - Messages view delegate

- (void)sendPressed:(UIButton *)sender withText:(NSString *)text {
    
    TSMessage *message = [[TSMessage alloc] initWithMessage:text sender:[TSKeyManager getUsernameToken] recipients:[[NSArray alloc] initWithObjects:self.contact.registeredID, nil] sentOnDate:[NSDate date] attachment:self.attachment];
    if(message.attachment.attachmentType!=TSAttachmentEmpty) {
        // this is asynchronous so message will only be send by messages manager when it succeeds
        [TSAttachmentManager uploadAttachment:message];
    }
    else {
        [[TSMessagesManager sharedManager] sendMessage:message];
    }
    [self.inputToolBarView.photoButton setImage:[UIImage imageNamed:@"photo.png"] forState:UIControlStateNormal];
    self.attachment = nil;
    [self finishSend];
}

- (void)photoPressed:(UIButton *)sender {
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo or Video",@"Choose Existing", nil];
    [actionSheet showInView:self.view];
    
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIImagePickerController *imagePicker =  [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    
    
    imagePicker.mediaTypes =  @[(NSString *) kUTTypeImage, (NSString *) kUTTypeMovie];
    
    imagePicker.allowsEditing = NO;
    
    switch (buttonIndex) {
        case 0:
            imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
            break;
        case 1:
            imagePicker.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        case 2:
            // cancel
            return;
        default:
            break;
    }
    [self presentViewController:imagePicker animated:YES completion:nil];
    
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    
    NSData* attachmentData;
    TSAttachmentType  attachmentType = TSAttachmentEmpty;
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        attachmentData= UIImagePNGRepresentation(image);
        attachmentType = TSAttachmentPhoto;
    }
    else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        
        attachmentData=[NSData dataWithContentsOfURL:videoURL];
        attachmentType = TSAttachmentVideo;
    }
    // encryption attachment data, write to file, and initialize the attachment
    NSData *randomEncryptionKey;
    NSData *encryptedData = [Cryptography encryptAttachment:attachmentData withRandomKey:&randomEncryptionKey];
    NSString* filename = [[Cryptography truncatedHMAC:encryptedData withHMACKey:randomEncryptionKey] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString* writeToFile = [FilePath pathInDocumentsDirectory:filename];
    [encryptedData writeToFile:writeToFile atomically:YES];
    self.attachment = [[TSAttachment alloc] initWithAttachmentDataPath:writeToFile withType:attachmentType withDecryptionKey:randomEncryptionKey];
    //size of button
    [self.inputToolBarView.photoButton setImage:[self.attachment getThumbnailOfSize:26] forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) reloadModel:(NSNotification*)notification {
    [self.tableView reloadData];
    NSLog(@"user info %@",[notification userInfo]);
    if([[[notification userInfo] objectForKey:@"messageType"] isEqualToString:@"send"]) {
        [JSMessageSoundEffect playMessageSentSound];
    }
    else {
        [JSMessageSoundEffect playMessageReceivedSound];
    }
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //TODO: error handling
    NSArray *dbMessages = [TSMessagesDatabase getMessagesOnThread:self.thread];
    
    if([[[dbMessages objectAtIndex:indexPath.row] senderId] isEqualToString:[TSKeyManager getUsernameToken]]) {
        return JSBubbleMessageTypeOutgoing;
    }
    else {
        return  JSBubbleMessageTypeIncoming;
    }
}

- (JSBubbleMessageStyle)messageStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return JSBubbleMessageStyleFlat;
}

- (JSMessagesViewTimestampPolicy)timestampPolicy {
    return JSMessagesViewTimestampPolicyEveryThree;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy {
    return JSMessagesViewAvatarPolicyNone;
}

- (JSAvatarStyle)avatarStyle {
    return JSAvatarStyleSquare;
}

- (JSInputBarStyle)inputBarStyle {
    return JSInputBarStyleFlat;
}

#pragma mark - Messages view data source
- (BOOL) shouldHaveThumbnailForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSArray *dbMessages = [TSMessagesDatabase getMessagesOnThread:self.thread];
    TSAttachment *attachment = [[dbMessages objectAtIndex:indexPath.row] attachment];
    return attachment.attachmentType != TSAttachmentEmpty;
}
- (UIImage *)thumbnailForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dbMessages = [TSMessagesDatabase getMessagesOnThread:self.thread];
    TSAttachment *attachment = [[dbMessages objectAtIndex:indexPath.row] attachment];
    return [attachment getThumbnailOfSize:100];
    
}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath {
    //TODO: error handling
    NSArray *dbMessages = [TSMessagesDatabase getMessagesOnThread:self.thread];
    return [[dbMessages objectAtIndex:indexPath.row] message];
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    //TODO: error handling
    NSArray *dbMessages = [TSMessagesDatabase getMessagesOnThread:self.thread];
    return [[dbMessages objectAtIndex:indexPath.row]  messageTimestamp];
}

- (UIImage *)avatarImageForIncomingMessage {
    return nil;
}

- (UIImage *)avatarImageForOutgoingMessage {
    return nil;
}

#pragma mark UITextViewDelegate (Sending box)

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([textView isEqual:self.inputToolBarView.textView]) {
        
        self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.view.frame.size.height - 44);
        
    }
    
    return true;
}

@end