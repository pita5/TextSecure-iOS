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
+(NSString*) uploadAttachment:(NSData*) attachement;
#pragma mark downloading files
+(NSData*) retrieveAttachmentForId:(NSString*)attachmentId;


@end
