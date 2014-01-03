//
//  TSRequest.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 9/27/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSRequest : NSMutableURLRequest

@property (nonatomic,retain) NSMutableDictionary *parameters;
@property (nonatomic,retain) NSData* data;
@property (nonatomic,retain) NSString* mimeType;
- (void) makeAuthenticatedRequest;
- (BOOL) usingExternalServer;
@end
