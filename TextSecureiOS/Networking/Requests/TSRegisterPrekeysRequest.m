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
#warning this method needs to be tested
  self = [super initWithURL:[NSURL URLWithString:textSecureKeysAPI]];
  self.HTTPMethod = @"PUT";
  NSString *publicIdentityKey = [[identityKey getPublicKey] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  NSMutableArray *serializedPrekeyList = [[NSMutableArray alloc] init];
  NSMutableDictionary *serializedKeyRegistrationParameters = [[NSMutableDictionary alloc] init];
  for(TSECKeyPair *pk in prekeys) {
    if([pk getPreKeyId]==0xFFFFFF){
      [serializedKeyRegistrationParameters addEntriesFromDictionary:
        [NSDictionary dictionaryWithObjects:@[[NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInt:[pk getPreKeyId]], [[pk getPublicKey] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength], publicIdentityKey] forKeys:@[@"keyId",@"publicKey",@"identityKey"]]]
                                    forKeys:@[@"lastResortKey"]]];
    }
    else {
      [serializedPrekeyList addObject:[NSDictionary dictionaryWithObjects:@[[NSNumber numberWithInt:[pk getPreKeyId]],[[pk getPublicKey] base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength], publicIdentityKey] forKeys:@[@"keyId",@"publicKey",@"identityKey"]]];
    }
  }
  [serializedKeyRegistrationParameters addEntriesFromDictionary:
    [NSDictionary dictionaryWithObjects:@[serializedPrekeyList] forKeys:@[@"keys"]]];
  self.parameters = serializedKeyRegistrationParameters;
  return self;
}

@end
