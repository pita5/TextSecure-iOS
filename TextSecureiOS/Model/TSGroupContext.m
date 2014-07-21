//
//  TSGroupContext.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/9/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//

#import "TSGroupContext.h"
#import "Cryptography.h"
#import "Constants.h"
#import "NSData+Base64.h"
#import "NSString+Conversion.h"
@implementation TSGroupContext

-(id)initWithId:(NSData*)groupId withName:(NSString*)groupName withAvatar:(TSAttachment*)avatar{
    return [self initWithId:groupId withType:TSUnknownGroupContext withName:groupName withMembers:[[NSMutableArray alloc] init] withAvatar:avatar];
}

-(id)initWithId:(NSData*)groupId withType:(TSGroupContextType)groupType withName:(NSString*)groupName withMembers:(NSArray*)groupMembers withAvatar:(TSAttachment*)groupAvatar {
    if(self=[super init]) {
        self.gid = groupId;
        self.type = groupType;
        self.name = groupName;
        self.members = groupMembers;
        self.avatar = groupAvatar;
    }
    return self;
}

+(NSData*) createNewGroupId {
    NSData* randomId = [Cryptography generateRandomBytes:32];
    return randomId;
}

-(NSString*) getEncodedId {
    return [self.gid base64EncodedString];
}

-(NSData*) getDecodedId:(NSString*)encodedId {
    return [NSData dataFromBase64String:encodedId];
}

@end
