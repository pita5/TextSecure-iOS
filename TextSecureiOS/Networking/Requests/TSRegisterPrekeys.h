//
//  TSRegisterPrekeys.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/17/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSRequest.h"
@class ECKeyPair;

@interface TSRegisterPrekeys : TSRequest

- (id)initWithPrekeyArray:(NSArray*)prekeys identityKey:(ECKeyPair*) identityKey;

@end
