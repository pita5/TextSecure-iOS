    //
//  ComposeMessageViewController.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 10/30/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSMessageViewController.h"
#import "TSMessagesManager.h"
#import "TSContactManager.h"
#import "TSContact.h"
#import "TSMessagesDatabase.h"
#import "TSMessageOutgoing.h"
#import "TSKeyManager.h"
#import "TSAttachment.h"
#import "TSAttachmentManager.h"
#import "Cryptography.h"
#import "FilePath.h"
#import "TSGroup.h"
#import "Emoticonizer.h"
#import "TSVerifyIdentityViewController.h"

@interface TSMessageViewController ()

@property (nonatomic, retain) NSArray *contacts;
@property (nonatomic, retain) NSArray *messages;

@end

@implementation TSMessageViewController

- (void)reloadMessages {
    if (!self.group) {
        self.messages = [TSMessagesDatabase messagesWithContact:self.contact];
    }

    [self.tableView reloadData];
}

-(void) setupThread  {
    self.title = [self.contact name];
    [self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)]; //scrolls to bottom
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ProfileSegue"])  {

        ((TSVerifyIdentityViewController*)segue.destinationViewController).contact = self.contact;
    }
}

- (void) dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupThread];
    self.delegate = self;
    self.dataSource = self;
    if (self.group) {
        if([[self.group groupName] length]>0) {
            self.title = self.group.groupName;
        }
        else if ([self.group isNonBroadcastGroup]) {
            self.title = @"Group message";
        }
        else {
            self.title = @"Broadcast message";
        }
    } else {
        self.messages = [TSMessagesDatabase messagesWithContact:self.contact];
    }

    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.view.frame.size.height - 44);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kDBNewMessageNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadMessages];
            [self.tableView reloadData];
        });
    }];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserverForName:self.contact.registeredID object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contact = [TSMessagesDatabase contactForRegisteredID:self.contact.registeredID];
            [self displayProfileOptionIfAvailable];
        });
    }];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    [self displayProfileOptionIfAvailable];
}

#pragma mark - Table view data source

-(void) displayProfileOptionIfAvailable {
    if(self.contact.identityKey && !self.contact.identityKeyIsVerified) {
        self.navigationItem.rightBarButtonItem.enabled=YES;
        
    }
    else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messages count];
}

#pragma mark - Messages view delegate

- (JSMessageInputViewStyle)inputViewStyle{
    return JSMessageInputViewStyleFlat;
}

- (JSMessagesViewSubtitlePolicy)subtitlePolicy{
    return JSMessagesViewSubtitlePolicyNone;
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

- (NSString *)subtitleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil;
}

- (void)didSendText:(NSString *)text {

    TSMessageOutgoing *message = [[TSMessageOutgoing alloc]initMessageWithContent:text recipient:self.contact.registeredID date:[NSDate date] attachements:@[] group:nil state:TSMessageStatePendingSend];

    //    if(message.attachment.attachmentType!=TSAttachmentEmpty) {
    //        // this is asynchronous so message will only be send by messages manager when it succeeds
    //        [TSAttachmentManager uploadAttachment:message];
    //    }

    [[TSMessagesManager sharedManager] scheduleMessageSend:message];
    [self reloadMessages];

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
    //NSString* filename = [[Cryptography truncatedHMAC:encryptedData withHMACKey:randomEncryptionKey truncation:10] base64EncodedStringWithOptions:0];
    //NSString* writeToFile = [FilePath pathInDocumentsDirectory:filename];
    //[encryptedData writeToFile:writeToFile atomically:YES];
    //self.attachment = [[TSAttachment alloc] initWithAttachmentDataPath:writeToFile withType:attachmentType withDecryptionKey:randomEncryptionKey];
    //size of button
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) reloadModel:(NSNotification*)notification {
    [self.tableView reloadData];
    if([[[notification userInfo] objectForKey:@"messageType"] isEqualToString:@"send"]) {
        [JSMessageSoundEffect playMessageSentSound];
    }
    else {
        [JSMessageSoundEffect playMessageReceivedSound];
    }
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (type == JSBubbleMessageTypeIncoming) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                          color:[UIColor js_bubbleLightGrayColor]];
    } else{

        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                          color:[UIColor js_bubbleBlueColor]];
    }
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[[self.messages objectAtIndex:indexPath.row] senderId] isEqualToString:[TSKeyManager getUsernameToken]]) {
        return JSBubbleMessageTypeOutgoing;
    }
    else {
        return  JSBubbleMessageTypeIncoming;
    }
}

- (JSMessagesViewTimestampPolicy)timestampPolicy {
    return JSMessagesViewTimestampPolicyEveryThree;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy {
    return JSMessagesViewAvatarPolicyNone;
}

#pragma mark - Messages view data source
//- (BOOL) shouldHaveThumbnailForRowAtIndexPath:(NSIndexPath*)indexPath {
//    TSAttachment *attachment = [[self.messages objectAtIndex:indexPath.row] attachment];
//    return attachment.attachmentType != TSAttachmentEmpty;
//}
//- (UIImage *)thumbnailForRowAtIndexPath:(NSIndexPath *)indexPath {
//    TSAttachment *attachment = [[self.messages objectAtIndex:indexPath.row] attachment];
//    return [attachment getThumbnailOfSize:100];
//}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [Emoticonizer emoticonizeString:[[self.messages objectAtIndex:indexPath.row] content]];
}

- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [(TSMessage*)[self.messages objectAtIndex:indexPath.row] timestamp];
}

- (UIImage *)avatarImageForIncomingMessage {
    return nil;
}

- (UIImage *)avatarImageForOutgoingMessage {
    return nil;
}

@end
