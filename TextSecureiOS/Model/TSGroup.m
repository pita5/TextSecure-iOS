//
//  TSGroup.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSGroup.h"

@implementation TSGroup

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        [copy setIsNonBroadcastGroup:self.isNonBroadcastGroup];
        [copy setGroupName:[self.groupName copy]]
        [copy setGroupImage:[self.groupImage copy]];
        
        TSGroupContext  *groupContext = [[TSGroupContext alloc] initWithId:self.groupContext.gid withType:self.groupContext.type withName:self.groupContext.name withMembers:self.groupContext.members withAvatar:self.groupContext.avatar];
        [copy setGroupContext:groupContext];
    }
    
    return copy;
}
@end
