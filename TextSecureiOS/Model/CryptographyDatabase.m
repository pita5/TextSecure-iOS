//
//  CryptographyDatabase.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "CryptographyDatabase.h"
#import "Cryptography.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "ECKeyPair.h"
#import "FilePath.h"

@implementation CryptographyDatabase
-(id) init {
	if(self==[super init]) {
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:@"cryptography.db"]];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
      BOOL success = [db setKey:[Cryptography getMasterSecretyKey]];
      if(!success) {
        @throw [NSException exceptionWithName:@"unable to encrypt" reason:@"this shouldn't happen" userInfo:nil];
        
      }
      [db executeUpdate:@"CREATE TABLE IF NOT EXISTS identity_key (private_key TEXT, public_key TEXT)"];
    }];
	}
	return self;
}

-(void) storeIdentityKey:(ECKeyPair*) identityKey {
  // TODO: actually store ECKey pair
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"INSERT INTO identity_key (private_key,public_key) VALUES (?, ?)",@"hello",@"world"];
  }];
  
}


-(ECKeyPair*) getIdentityKey {
  // TODO: actually return ECKey pair
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:@"SELECT * FROM identity_key"];
    while([rs next]){
      NSLog(@"identity key was %@ %@",[rs stringForColumn:@"private_key"],[rs stringForColumn:@"public_key"]);
      break;

    }
    [rs close];
  }];
  return nil;
}

@end
