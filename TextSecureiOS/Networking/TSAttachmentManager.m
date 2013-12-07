//
//  TSAttachmentManager.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/1/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSAttachmentManager.h"
#import "TSRequestAttachment.h"
#import "TSRequestAttachmentId.h"
#import "TSUploadAttachment.h"

@implementation TSAttachmentManager




-(NSString*) retrieveNewAttachmentUploadLocation {
  __block NSString* uploadLocation;
  [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRequestAttachmentId alloc] init] success:^(AFHTTPRequestOperation *operation, id responseObject) {
    switch (operation.response.statusCode) {
        // in both cases attachment info currently in header under "Content-Location " = "contentonamazonwebsite";
      case 200:
        uploadLocation = [responseObject objectForKey:@"location"];
        DLog(@"we have attachment id %@ location %@",responseObject,uploadLocation);
        break;
        
      default:
        DLog(@"Issue getting attachment ");
#warning Add error handling if not able to get contacts prekey
        break;
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
    DLog(@"failure attachment  %d, %@",operation.response.statusCode,operation.response.description);
    
    
  }];
  return uploadLocation;
}

-(BOOL) uploadAttachment:(NSData*) attachement {
#warning just testing attachments
  NSString* uploadLocation = [self retrieveNewAttachmentUploadLocation];
  [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSUploadAttachment alloc] initWithAttachment:attachement uploadLocation:uploadLocation] success:^(AFHTTPRequestOperation *operation, id responseObject) {
    switch (operation.response.statusCode) {
        // in both cases attachment info currently in header under "Content-Location " = "contentonamazonwebsite";
      case 200:
        break;
        
      default:
#warning Add error handling if not able to get contacts prekey
        break;
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
    
    
  }];

  
       
       
       
       
  
  
  
  
}

-(NSString*) retrieveAttachmentUploadLocationForId:(NSString*) attachmentId {
  __block NSString* uploadLocation;
  NSString* attachmentLocation = [self retrieveNewAttachmentUploadLocation];
  [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRequestAttachment alloc] initWithId:attachmentId] success:^(AFHTTPRequestOperation *operation, id responseObject) {
    switch (operation.response.statusCode) {
      case 200:
        uploadLocation = [responseObject objectForKey:@"location"];
        DLog(@"we have attachment id %@ location %@",responseObject,uploadLocation);
      default:
        DLog(@"Issue getting attachment ");
#warning Add error handling if not able to get contacts prekey
        break;
        
        
    }
  }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
    DLog(@"failure attachment  %d, %@",operation.response.statusCode,operation.response.description);
    
    
  }];
  return uploadLocation;
  
}
-(NSData*) retrieveAttachmentForId:(NSString*)attachmentId {
  NSString* uploadLoaction = [self retrieveAttachmentUploadLocationForId:attachmentId];

  __block NSData* attachment;
  
}


@end
