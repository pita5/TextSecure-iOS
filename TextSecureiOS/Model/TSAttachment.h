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
@property (nonatomic,strong) NSURL* attachmentUrl;

-(id) initWithAttachmentData:(NSData*) data  withType:(TSAttachmentType)type;

@end
