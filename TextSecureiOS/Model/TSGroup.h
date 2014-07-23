//
//  TSGroup.h
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSGroupContext.h"

@interface TSGroup : NSObject
@property(nonatomic,assign) BOOL isNonBroadcastGroup;
@property(nonatomic,strong) NSString *groupName;
@property(nonatomic,strong) UIImage *groupImage;
@property(nonatomic,strong) TSGroupContext *groupContext;

-(instancetype) initWithGroupContext:(TSGroupContext*)context;

@end
