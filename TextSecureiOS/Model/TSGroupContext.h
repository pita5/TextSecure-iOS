//
//  TSGroupContext.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/9/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSAttachment.h"

@interface TSGroupContext : NSObject
@property(nonatomic,strong) UIImage *image;
@property(nonatomic,assign) TSGroupContextType type;
@property(nonatomic,strong) NSData* gid;
@property(nonatomic,strong) NSString* name;

@property(nonatomic,strong) NSArray *members;
@property(nonatomic,strong) TSAttachment *avatar;


-(id)initWithId:(NSData*)groupId withType:(TSGroupContextType)groupType withName:(NSString*)groupName withMembers:(NSArray*)groupMembers withAvatar:(TSAttachment*)groupAvatar;
@end
