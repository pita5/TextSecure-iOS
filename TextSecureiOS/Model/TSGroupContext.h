//
//  TSGroupContext.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/9/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSProtocols.h"
#import "TSAttachment.h"

@interface TSGroupContext : NSObject
@property(nonatomic,strong) UIImage *groupImage;
@property(nonatomic,assign) TSGroupContextType groupType;
@property(nonatomic,strong) NSData* groupId;
@property(nonatomic,strong) NSArray *groupMembers;
@property(nonatomic,strong) TSAttachment *groupAvatar;

@end
