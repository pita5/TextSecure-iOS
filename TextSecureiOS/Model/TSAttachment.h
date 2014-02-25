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
@property (nonatomic,strong) NSString* attachmentDataPath;
@property (nonatomic) TSAttachmentType attachmentType;
@property (nonatomic,strong) NSNumber* attachmentId;
@property (nonatomic,strong) NSData* attachmentDecryptionKey;
@property (nonatomic,strong) NSURL* attachmentURL;
-(id) initWithAttachmentDataPath:(NSString*) dataPath  withType:(TSAttachmentType)type withDecryptionKey:attachmentDecryptionKey;
-(id) initWithAttachmentId:(NSNumber*)attachmentId contentMIMEType:(NSString*)contentType decryptionKey:(NSData*)decryptionKey;
-(UIImage*) getThumbnailOfSize:(int)size;
-(NSString*) getMIMEContentType;
-(NSData*) getData;
-(UIImage*) getImage;
-(BOOL) readyForUpload;

- (void)testUpload;

@end
