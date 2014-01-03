//
//  TSAttachmentManager.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TSAttachment;
@interface TSAttachmentManager : NSObject

#pragma mark uploading files
+(void) uploadAttachment:(TSAttachment*) attachement;
#pragma mark downloading files
+(void) downloadAttachment:(TSAttachment*)attachment;


@end
