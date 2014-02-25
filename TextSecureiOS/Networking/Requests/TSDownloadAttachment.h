//
//  TSDownloadAttachment.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/6/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSRequest.h"
@class TSAttachment;
@interface TSDownloadAttachment : TSRequest
@property (nonatomic,strong) TSAttachment* attachment;
-(TSRequest*) initWithAttachment:(TSAttachment*) attachment;
@end
