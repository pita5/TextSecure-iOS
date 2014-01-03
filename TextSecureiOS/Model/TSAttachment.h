//
//  TSAttachment.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/2/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
typedef enum {
  TSAttachmentEmpty,
  TSAttachmentPhoto,
  TSAttachmentVideo
} TSAttachmentType;
@interface TSAttachment : NSObject
@property (nonatomic,strong) NSData* attachmentData;
@property (nonatomic) TSAttachmentType attachmentType;
@property (nonatomic,strong) NSString* attachmentId;
@property (nonatomic,strong) UIImage* attachmentThumbnail;
-(id) initWithAttachmentData:(NSData*) data  withType:(TSAttachmentType)type withThumbnailImage:(UIImage*)thumbnail;
-(UIImage*) getThumbnailOfSize:(int)size;
-(NSString*) getMIMEContentType;
@end
