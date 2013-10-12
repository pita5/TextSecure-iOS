//
//  CryptographyDatabase.h
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECKeyPair;
@class FMDatabaseQueue;
@interface CryptographyDatabase : NSObject
@property (nonatomic,strong) FMDatabaseQueue *dbQueue;
-(void) storeIdentityKey:(ECKeyPair*) identityKey;
-(ECKeyPair*) getIdentityKey;
@end
