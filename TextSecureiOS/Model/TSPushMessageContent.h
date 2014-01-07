//
//  TSPushMessageContent.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 1/7/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSPushMessageContent : NSObject
@property (nonatomic,strong) NSString* body;
@property (nonatomic,strong) NSArray* attachments;
@end
