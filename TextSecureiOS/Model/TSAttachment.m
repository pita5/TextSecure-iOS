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
#import <MediaPlayer/MediaPlayer.h>
#import "Cryptography.h"
@implementation TSAttachment

-(id) initWithAttachmentDataPath:(NSString*) dataPath  withType:(TSAttachmentType)type withDecryptionKey:(NSData*)decryptionKey {
  if(self=[super init]) {
    self.attachmentDataPath = dataPath;
    self.attachmentType = type;
    self.attachmentDecryptionKey = decryptionKey;
  }
  return self;
}


-(NSData*) decryptedAttachmentData:(BOOL)isThumbnail {
  NSData *attachmentData = [NSData dataWithContentsOfFile:self.attachmentDataPath options:NSDataReadingUncached error:nil];
  NSData *decryptedData= [Cryptography decryptAttachment:attachmentData withKey:self.attachmentDecryptionKey];
  if (isThumbnail && self.attachmentType==TSAttachmentVideo) {
    return UIImagePNGRepresentation([UIImage imageNamed:@"movie.png"]);
  }
  return decryptedData;
}
-(UIImage*) getThumbnailOfSize:(int)size {
  UIImage* thumbnailImage = [UIImage imageWithData:[self decryptedAttachmentData:YES]];
  return  [thumbnailImage thumbnailImage:size transparentBorder:0 cornerRadius:3.0 interpolationQuality:0];
}

-(UIImage*) getImage  {
  return [UIImage imageWithData:[self decryptedAttachmentData:YES]];

}

-(NSData*) getData {
  return  [self decryptedAttachmentData:NO];

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
