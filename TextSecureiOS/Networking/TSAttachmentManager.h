//
//  TSAttachmentManager.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSAttachmentManager : NSObject
#pragma mark uploading files
-(NSString*) retrieveNewAttachmentUploadLocation;
-(BOOL) uploadAttachment:(NSData*) attachement;
#pragma mark downloading files
-(NSString*) retrieveAttachmentUploadLocationForId:(NSString*) attachmentId;
-(NSData*) retrieveAttachmentForId:(NSString*)attachmentId;


@end
