//
//  TSUploadAttachment.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 12/3/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRequest.h"
@class TSAttachment;
@interface TSUploadAttachment : TSRequest
-(TSRequest*) initWithAttachment:(TSAttachment*) attachment ;
@end
