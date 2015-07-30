//
//  TSGroup.m
//  TextSecureiOS
//
//  Created by Frederic Jacobs on 01/03/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSGroup.h"

@implementation TSGroup

-(instancetype) initWithGroupContext:(TSGroupContext*)context {
    if(self = [super init]) {
        self.groupContext = [[TSGroupContext alloc] initWithId:context.gid withType:context.type withName:context.name withMembers:context.members withAvatar:context.avatar];
        self.groupName = self.groupContext.name;
        self.groupImage = self.groupContext.image;
    }
    return self;
}



-(instancetype) groupContextForDelivery {
    TSGroup* group = [[TSGroup alloc] init];
    group.isBroadcastGroup = self.isBroadcastGroup;
    group.groupContext=[[TSGroupContext alloc] initWithId:self.groupContext.gid withType:TSDeliverGroupContext withName:nil withMembers:nil withAvatar:nil];
    return group;
}

- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        [copy setIsBroadcastGroup:self.isBroadcastGroup];
        [copy setGroupName:[self.groupName copy]];
        [copy setGroupImage:[self.groupImage copy]];
        
        TSGroupContext  *groupContext = [[TSGroupContext alloc] initWithId:self.groupContext.gid withType:self.groupContext.type withName:self.groupContext.name withMembers:self.groupContext.members withAvatar:self.groupContext.avatar];
        [copy setGroupContext:groupContext];
    }
    
    return copy;
}
@end
