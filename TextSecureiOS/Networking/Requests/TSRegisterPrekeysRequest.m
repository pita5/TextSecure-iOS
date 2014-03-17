//
//  TSRegisterPrekeys.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/17/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRegisterPrekeysRequest.h"
#import "TSECKeyPair.h"
@implementation TSRegisterPrekeysRequest

- (id)initWithPrekeyArray:(NSArray*)prekeys identityKey:(TSECKeyPair*) identityKey{
    
    self = [super initWithURL:[NSURL URLWithString:textSecureKeysAPI]];
    self.HTTPMethod = @"PUT";
    NSString *publicIdentityKey = [[identityKey publicKeyWithVersionByte] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSMutableArray *serializedPrekeyList = [[NSMutableArray alloc] init];
    NSMutableDictionary *serializedKeyRegistrationParameters = [[NSMutableDictionary alloc] init];
    for(TSECKeyPair *pk in prekeys) {
        if([pk preKeyId]==kLastResortKeyId){
            [serializedKeyRegistrationParameters addEntriesFromDictionary:
             [NSDictionary dictionaryWithObjects:@[[NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInt:[pk preKeyId]], [[pk publicKeyWithVersionByte] base64EncodedStringWithOptions:0], publicIdentityKey] forKeys:@[@"keyId",@"publicKey",@"identityKey"]]]
                                         forKeys:@[@"lastResortKey"]]];
        }
        else {
            [serializedPrekeyList addObject:[NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInt:[pk preKeyId]],[[pk publicKey] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength], publicIdentityKey] forKeys:@[@"keyId",@"publicKey",@"identityKey"]]];
        }
    }
    [serializedKeyRegistrationParameters addEntriesFromDictionary:
     [NSDictionary dictionaryWithObjects:@[serializedPrekeyList] forKeys:@[@"keys"]]];
    self.parameters = serializedKeyRegistrationParameters;
    
    return self;
}

@end
