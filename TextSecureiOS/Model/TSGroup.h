//
//  TSGroup.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/8/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSGroup : NSObject
@property(nonatomic,assign) BOOL isNonBroadcastGroup;
@property(nonatomic,strong) UIImage *groupImage;
@property(nonatomic,strong) NSString *groupName;
@end
