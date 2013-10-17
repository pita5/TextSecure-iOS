//
//  TSRegisterPrekeys.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/17/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRegisterPrekeys.h"
#import "ECKeyPair.h"
@implementation TSRegisterPrekeys

- (id)initWithPrekeyArray:(NSArray*)prekeys identityKey:(ECKeyPair*) identityKey{
#warning this method needs to be tested
  self = [super initWithURL:[NSURL URLWithString:textSecureKeysAPI]];
  self.HTTPMethod = @"PUT";
  NSString *publicIdentityKey = [identityKey publicKey];
  NSMutableArray *serializedPrekeyList = [[NSMutableArray alloc] init];
  NSMutableDictionary *serializedKeyRegistrationParameters = [[NSMutableDictionary alloc] init];
  for(ECKeyPair *pk in prekeys) {
    if([pk prekeyId]==16777216){
      [serializedKeyRegistrationParameters addEntriesFromDictionary:
        [NSDictionary dictionaryWithObjects:@[[NSDictionary dictionaryWithObjects:@[[NSNumber  numberWithInt:[pk prekeyId]],[pk publicKey],publicIdentityKey] forKeys:@[@"keyId",@"publicKey",@"identityKey"]]]
                                    forKeys:@[@"lastResortKey"]]];
    }
    else {
      [serializedPrekeyList addObject:[NSDictionary dictionaryWithObjects:@[[NSNumber  numberWithInt:[pk prekeyId]],[pk publicKey],publicIdentityKey] forKeys:@[@"keyId",@"publicKey",@"identityKey"]]];
    }
  }
  [serializedKeyRegistrationParameters addEntriesFromDictionary:
    [NSDictionary dictionaryWithObjects:@[serializedPrekeyList] forKeys:@[@"keys"]]];
  self.parameters = serializedKeyRegistrationParameters;
  return self;
}

@end
