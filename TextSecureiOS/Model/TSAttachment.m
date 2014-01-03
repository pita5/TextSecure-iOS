//
//  TSAttachment.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/2/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSAttachment.h"
#import <UIImage-Categories/UIImage+Resize.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFNetworking.h>

@implementation TSAttachment

-(id) initWithAttachmentDataPath:(NSString*) dataPath  withType:(TSAttachmentType)type withThumbnailImagePath:(NSString*)thumbnailImagePath withDecryptionKey:(NSData*)decryptionKey {
  if(self=[super init]) {
    self.attachmentDataPath = dataPath;
    self.attachmentType = type;
    self.attachmentThumbnailPath=thumbnailImagePath;
    self.attachmentDecryptionKey = decryptionKey;
  }
  return self;
}


-(UIImage*) getThumbnailOfSize:(int)size {
  NSData *thumbnailData = [NSData dataWithContentsOfFile:self.attachmentThumbnailPath options:NSDataReadingUncached error:nil];
  //later decrypt
  UIImage* thumbnailImage = [UIImage imageWithData:thumbnailData];
  return  [thumbnailImage thumbnailImage:size transparentBorder:0 cornerRadius:3.0 interpolationQuality:0];
}

-(UIImage*) getImage  {
  NSData *attachmentData = [NSData dataWithContentsOfFile:self.attachmentDataPath options:NSDataReadingUncached error:nil];
  //later decrypt
  return [UIImage imageWithData:attachmentData];

}

-(NSData*) getData {
  return  [NSData dataWithContentsOfFile:self.attachmentDataPath options:NSDataReadingUncached error:nil];

}

-(NSString*) getMIMEContentType {
  switch (self.attachmentType) {
    case TSAttachmentEmpty:
      return @"";
      break;
    case TSAttachmentPhoto:
      return @"image/png";
      break;
    case TSAttachmentVideo:
      return @"video/mp4";
    default:
      return @"";
      break;
  }
}

-(BOOL) readyForUpload {
  return (self.attachmentType != TSAttachmentEmpty && self.attachmentId != nil && self.attachmentURL != nil);
}

@end
