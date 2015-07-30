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
#import "FilePath.h"
@implementation TSAttachment

-(id) initWithAttachmentDataPath:(NSString*) dataPath  withType:(TSAttachmentType)type withDecryptionKey:(NSData*)decryptionKey {
    if(self=[super init]) {
        self.attachmentDataPath = dataPath;
        self.attachmentType = type;
        self.attachmentDecryptionKey = decryptionKey;
    }
    return self;
}

-(id) initWithAttachmentId:(NSNumber*)attachmentId contentMIMEType:(NSString*)contentType decryptionKey:(NSData*)decryptionKey {
    if(self=[super init]) {
        self.attachmentId = attachmentId;
        self.attachmentDecryptionKey = decryptionKey;
#warning download attachment here
        // encryption attachment data, write to file, and initialize the attachment
        /*
        NSData *randomEncryptionKey;
        NSData *encryptedData = [Cryptography encryptAttachment:UIImagePNGRepresentation([UIImage imageNamed:@"photo.png"]) withKey:decryptionKey
        
        NSString* filename = [[Cryptography truncatedHMAC:encryptedData withHMACKey:randomEncryptionKey truncation:10] base64EncodedStringWithOptions:0];
        
        NSString* writeToFile = [FilePath pathInDocumentsDirectory:filename];
        [encryptedData writeToFile:writeToFile atomically:YES];
         */
        self.attachmentDecryptionKey = decryptionKey;
        self.attachmentDataPath = @"TODOFILE";
        self.attachmentType = [contentType isEqualToString:@"video/mp4"] ? TSAttachmentVideo : TSAttachmentPhoto;
        
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
