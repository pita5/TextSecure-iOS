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
    NSString* serializedPrekeyId= [NSString stringWithFormat:@"0x%06X",[pk prekeyId]];
    if([pk prekeyId]==16777215){
      [serializedKeyRegistrationParameters addEntriesFromDictionary:
        [NSDictionary dictionaryWithObjects:@[[NSDictionary dictionaryWithObjects:@[serializedPrekeyId,[pk publicKey],publicIdentityKey] forKeys:@[@"keyId",@"publicKey",@"identityKey"]]]
                                    forKeys:@[@"lastResortKey"]]];
    }
    else {
      //  //[NSString stringWithFormat:@"%06X",prekeyCounter] to hex format

      [serializedPrekeyList addObject:[NSDictionary dictionaryWithObjects:@[serializedPrekeyId,[pk publicKey],publicIdentityKey] forKeys:@[@"keyId",@"publicKey",@"identityKey"]]];
    }
  }
  [serializedKeyRegistrationParameters addEntriesFromDictionary:
    [NSDictionary dictionaryWithObjects:@[serializedPrekeyList] forKeys:@[@"keys"]]];
  self.parameters = serializedKeyRegistrationParameters;
  return self;
}

@end
