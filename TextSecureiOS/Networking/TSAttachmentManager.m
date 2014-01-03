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
#import "TSAttachment.h"

@implementation TSAttachmentManager






+(void) uploadAttachment:(TSAttachment*) attachment {

  
#warning error handling
  [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRequestAttachmentId alloc] init] success:^(AFHTTPRequestOperation *operation, id responseObject) {
    switch (operation.response.statusCode) {
        // in both cases attachment info currently in header under "Content-Location " = "contentonamazonwebsite";
      case 200: {
        attachment.attachmentId = [responseObject objectForKey:@"id"];
        attachment.attachmentURL = [NSURL URLWithString:[responseObject objectForKey:@"location"]];
        DLog(@"we have attachment id %@ location %@",attachment.attachmentId,attachment.attachmentURL);
        [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSUploadAttachment alloc] initWithAttachment:attachment] success:^(AFHTTPRequestOperation *uploadOperation, id uploadResponseObject) {
          switch (uploadOperation.response.statusCode) {
              
            case 200:
              NSLog(@"upload success");
              break;
              
            default:
              break;
          }
        } failure:^(AFHTTPRequestOperation *uploadOperation, NSError *uploadError) {
          DLog(@"failure with uploading file, %d,   %@",uploadOperation.response.statusCode,uploadOperation.response.description);

          
        }];
        
        break;
      }
        
      default:
        DLog(@"Issue getting attachment upload location ");
#warning Add error handling if not able to get contacts prekey
        break;
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
    DLog(@"failure allocated upload location %d, %@",operation.response.statusCode,operation.response.description);
    
    
  }];
  
  

}

+(void) downloadAttachment:(TSAttachment*)attachment {
#warning error handling
  [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRequestAttachment alloc] initWithId:attachment.attachmentId] success:^(AFHTTPRequestOperation *operation, id responseObject) {
    switch (operation.response.statusCode) {
      case 200: {
        NSString* uploadLocation = [responseObject objectForKey:@"location"];
        // Now, download the data
        DLog(@"we have attachment id %@ location %@",responseObject,uploadLocation);
        break;
      }
      default:
        DLog(@"Issue getting attachment upload location ");
        break;
        
        
    }
  }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    
    DLog(@"failure attachment  %d, %@",operation.response.statusCode,operation.response.description);
    
    
  }];

#warning not implemented yet
#warning error handling
}


@end
