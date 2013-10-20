//
//  CryptographyDatabase.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 10/12/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "EncryptedDatabase.h"
#import "Cryptography.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "ECKeyPair.h"
#import "FilePath.h"

#define kKeyForInitBool @"DBWasInit"

static EncryptedDatabase *SharedCryptographyDatabase = nil;


@implementation EncryptedDatabase
-(id) init {
  @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"must be initialized with password" userInfo:nil];
  
}

+(void) setupDatabaseWithPassword:(NSString*) userPassword {
  if (!SharedCryptographyDatabase) {
    //first call of this during the app lifecyle
    SharedCryptographyDatabase = [[EncryptedDatabase alloc] initWithPassword:userPassword];
  }
  // We also want to generate the identity keys if they haven't been
  if(![SharedCryptographyDatabase getIdentityKey]) {
    [Cryptography generateAndStoreIdentityKey];
    [Cryptography generateAndStoreNewPreKeys:70];
  }
}


+(id) database {
  if (!SharedCryptographyDatabase) {
     @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"database must be accessed with password prior to being able to use this method" userInfo:nil];
  }
  return SharedCryptographyDatabase;
  
}



-(id) initWithPassword:(NSString*) userPassword {
  if(self=[super init]) {
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:@"cryptography.db"]];
    [self.dbQueue inDatabase:^(FMDatabase *db) {
      NSData * key = [Cryptography getMasterSecretKey:userPassword];
      if(key!=nil) {
        BOOL success = [db setKeyWithData:key];
        if(!success) {
          @throw [NSException exceptionWithName:@"unable to encrypt" reason:@"this shouldn't happen" userInfo:nil];
          
        }
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS persistent_settings (setting_name TEXT UNIQUE,setting_value TEXT)"];
        [db executeUpdate:@"CREATE TABLE IF NOT EXISTS personal_prekeys (prekey_id INTEGER UNIQUE,public_key TEXT,private_key TEXT, last_counter INTEGER)"];
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kKeyForInitBool];
        [[NSUserDefaults standardUserDefaults] synchronize];
      }
    }];
	}
	return self;

}

+(BOOL) dataBaseWasInitialized{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKeyForInitBool];
}

-(void) savePersonalPrekeys:(NSArray*)prekeyArray {
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    for(ECKeyPair* keyPair in prekeyArray) {
      [db executeUpdate:@"INSERT OR REPLACE INTO personal_prekeys (prekey_id,public_key,private_key,last_counter) VALUES (?,?,?,?)",[NSNumber numberWithInt:[keyPair prekeyId]],[keyPair publicKey],[keyPair privateKey],[NSNumber numberWithInt:0]];
    }
  }];
}

-(NSArray*) getPersonalPrekeys {
  NSMutableArray *prekeyArray = [[NSMutableArray alloc] init];
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM personal_prekeys"]];
    while([rs next]) {
      ECKeyPair *keyPair = [[ECKeyPair alloc] initWithPublicKey:[rs stringForColumn:@"public_key"]
                                                     privateKey:[rs stringForColumn:@"private_key"]
                                                       prekeyId:[rs intForColumn:@"prekey_id"]];
      [prekeyArray addObject:keyPair];
    }
  }];
  return prekeyArray;
}


-(int) getLastPrekeyId {
  __block int counter = -1;
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT prekey_id FROM personal_prekeys WHERE last_counter=\"1\""]];
    if([rs next]){
      counter = [rs intForColumn:@"prekey_id"];
    }
    [rs close];
    
  }];
  return counter;
  
}

-(void) setLastPrekeyId:(int)lastPrekeyId {
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"UPDATE personal_prekeys SET last_counter=0"];
    [db executeUpdate:[NSString stringWithFormat:@"UPDATE personal_prekeys SET last_counter=1 WHERE prekey_id=%d",lastPrekeyId]];
  }];
}


-(void) storeIdentityKey:(ECKeyPair*) identityKey {
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?, ?)",@"identity_key_private",[identityKey privateKey]];
    [db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?, ?)",@"identity_key_public",[identityKey publicKey]];
  }];
  
}


-(ECKeyPair*) getIdentityKey {
  __block NSString* identityKeyPrivate = nil;
  __block NSString* identityKeyPublic = nil;
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT setting_value FROM persistent_settings WHERE setting_name=\"identity_key_public\""]];
    if([rs next]){
      identityKeyPublic = [rs stringForColumn:@"setting_value"];
    }
    [rs close];
    rs = [db executeQuery:[NSString stringWithFormat:@"SELECT setting_value FROM persistent_settings WHERE setting_name=\"identity_key_private\""]];

    if([rs next]){
      identityKeyPrivate = [rs stringForColumn:@"setting_value"];
    }
    [rs close];
  }];
  if(identityKeyPrivate==nil || identityKeyPublic==nil) {
    return nil;
  }
  else {
    return [[ECKeyPair alloc] initWithPublicKey:identityKeyPublic privateKey:identityKeyPrivate];
  }
}

@end
