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
#import "TSMessage.h"
#import "TSAttachment.h"
#import "TSMessagesManager.h"
#import "TSDownloadAttachment.h"
#import "Cryptography.h"
#import "FilePath.h"
@implementation TSAttachmentManager

+(void) uploadAttachment:(TSMessage*) message {
    
#warning error handling
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRequestAttachmentId alloc] init] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        switch (operation.response.statusCode) {
                // in both cases attachment info currently in header under "Content-Location " = "contentonamazonwebsite";
            case 200: {
                message.attachment.attachmentId = [responseObject objectForKey:@"id"];
                message.attachment.attachmentURL = [NSURL URLWithString:[responseObject objectForKey:@"location"]];
                DLog(@"we have attachment id %@ location %@",message.attachment.attachmentId,message.attachment.attachmentURL);
                //[TSAttachmentManager downloadAttachment:message]; // remove testing to see if upload = download
#warning later do this only after the attachment has been uploaded but still having success issues so am doing before for now.
                // we can now send the messsage
               // [[TSMessagesManager sharedManager] sendMessage:message];
                [[TSNetworkManager sharedManager] queueUnauthenticatedRequest:[[TSUploadAttachment alloc] initWithAttachment:message.attachment] success:^(AFHTTPRequestOperation *uploadOperation, id uploadResponseObject) {
                    switch (uploadOperation.response.statusCode) {
                            
                        case 200: {
                            NSLog(@"upload file success!!!!!");
#warning remove this testing
                            
                            break;
                        }
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

+(void) downloadAttachment:(TSMessage*) message {
    /*
     example:
     TSMessage *newMessage = [[TSMessage alloc] initWithMessage:@"" sender:@"" recipients:nil sentOnDate:nil attachment:[[TSAttachment alloc] init]];
     newMessage.attachment.attachmentId = [NSNumber numberWithUnsignedLongLong:7752343503763367516];
     [TSAttachmentManager downloadAttachment:newMessage];
     */
#warning error handling
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRequestAttachment alloc] initWithId:message.attachment.attachmentId] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        switch (operation.response.statusCode) {
            case 200: {
                NSString* uploadLocation = [responseObject objectForKey:@"location"];
                // Now, download the data
                DLog(@"we have attachment download id %@ location %@",responseObject,uploadLocation);
                message.attachment.attachmentURL = [NSURL URLWithString:[responseObject objectForKey:@"location"]];
                
                
                [[TSNetworkManager sharedManager] queueUnauthenticatedRequest:[[TSDownloadAttachment alloc] initWithAttachment:message.attachment] success:^(AFHTTPRequestOperation *downloadOperation, id downloadResponseObject) {
                    switch (downloadOperation.response.statusCode) {
                            
                        case 200:{
                            NSLog(@"download file success!!!!!");
                            // Save the file
                            NSData* attachmentData = downloadResponseObject;
                            NSData *hmacKey = [Cryptography generateRandomBytes:32];
                            message.attachment.attachmentDataPath = [FilePath pathInDocumentsDirectory:[[Cryptography truncatedHMAC:attachmentData withHMACKey:hmacKey truncation:10]base64EncodedStringWithOptions:0]];
                            [attachmentData writeToFile:message.attachment.attachmentDataPath atomically:YES];
                            
                            break;
                        }
                        default:
                            break;
                    }
                } failure:^(AFHTTPRequestOperation *downloadOperation, NSError *downloadError) {
                    DLog(@"failure with uploading file, %d,   %@",downloadOperation.response.statusCode,downloadOperation.response.description);
                    
                    
                }];
                break;
            }
            default:
                DLog(@"Issue getting attachment upload location ");
                break;
                
                
        }
    }failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        DLog(@"failure attachment  %d, %@",operation.response.statusCode,operation.response.description);
        
        
    }];
}

-(NSData*) retrieveAttachmentForId:(NSString*)attachmentId {
# warning not implemented
}


@end
