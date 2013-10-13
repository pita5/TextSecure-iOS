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
+(void) setupDatabaseWithPassword:(NSString*) userPassword;
+(id) database;
-(void) rekeyWithPassword:(NSString*) userPassword;
-(id) initWithPassword:(NSString*) userPassword;
-(id) init;
-(void) storeIdentityKey:(ECKeyPair*) identityKey;
-(ECKeyPair*) getIdentityKey;
-(void) savePrekeyCounter:(NSString*)prekeyCounter;
-(NSNumber*) getPrekeyCounter;
-(void) incrementPrekeyCounter;
-(void) generatePrekeyCounterIfNeeded;
@end
