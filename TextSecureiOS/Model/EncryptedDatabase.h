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
@interface EncryptedDatabase : NSObject
@property (nonatomic,strong) FMDatabaseQueue *dbQueue;
+(void) setupDatabaseWithPassword:(NSString*) userPassword;
-(id) initWithPassword:(NSString*) userPassword;

+(id) database;
-(id) init;
-(void) storeIdentityKey:(ECKeyPair*) identityKey;
-(ECKeyPair*) getIdentityKey;
-(int) getLastPrekeyId;
-(void) setLastPrekeyId:(int)lastPrekeyId;
-(void) savePersonalPrekeys:(NSArray*)prekeyArray;
-(NSArray*) getPersonalPrekeys;
@end
