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
      }
      
    }];
	}
  [self generatePrekeyCounterIfNeeded];
	return self;

}



-(void) generatePrekeyCounterIfNeeded {
  if([self getPrekeyCounter]==nil) {
    // we generate the prekey counter
    [self.dbQueue inDatabase:^(FMDatabase *db) {

      NSNumber *baseInt = [NSNumber numberWithUnsignedInteger: arc4random() % 16777216]; //16777216 is 0xFFFFFF
      NSString *prekeyCounter = [NSString stringWithFormat:@"%06X", [baseInt unsignedIntegerValue]];
      [db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?,?)",@"prekey_counter",prekeyCounter];
    }];

  }
}

-(void) savePrekeyCounter:(NSString*)prekeyCounter {
  [self.dbQueue inDatabase:^(FMDatabase *db) {
      [db executeUpdate:@"INSERT OR REPLACE INTO  persistent_settings (setting_name,setting_value) VALUES (?,?)",@"prekey_counter",prekeyCounter];
  }];
  
}

-(void) incrementPrekeyCounter {
  unsigned int prekeyCounter = [[self getPrekeyCounter] unsignedIntegerValue];
  prekeyCounter++;
  [self savePrekeyCounter:[NSString stringWithFormat:@"%06X",prekeyCounter % 16777216]]; //16777216 is 0xFFFFFF

}

-(NSNumber*) getPrekeyCounter {
  __block NSNumber* counter = nil;
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT setting_value FROM persistent_settings WHERE setting_name=\"prekey_counter\""]];
    while([rs next]){
      NSString* prekeyCounter = [rs stringForColumn:@"setting_value"];
      NSScanner* pScanner = [NSScanner scannerWithString: prekeyCounter];
      
      unsigned int iValue;
      [pScanner scanHexInt: &iValue];
      counter=[NSNumber numberWithUnsignedInteger:iValue];
      break;
    }
    [rs close];
    
  }];
  return counter;
  
}


-(void) storeIdentityKey:(ECKeyPair*) identityKey {
  // TODO: actually store ECKey pair
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    [db executeUpdate:@"INSERT OR REPLACE INTO persitent_settings (setting_name,setting_value) VALUES (?, ?)",@"identity_key_private",@"hello"];
    [db executeUpdate:@"INSERT OR REPLACE INTO persitent_settings (setting_name,setting_value) VALUES (?, ?)",@"identity_key_public",@"world"];
  }];
  
}


-(ECKeyPair*) getIdentityKey {
  // TODO: actually return ECKey pair
  [self.dbQueue inDatabase:^(FMDatabase *db) {
    FMResultSet  *rs = [db executeQuery:@"SELECT identity_key_public FROM persistent_settings"];
    while([rs next]){
      NSLog(@"identity key public %@",[rs stringForColumn:@"setting_value"]);
      break;

    }
    [rs close];
  }];
  return nil;
}

@end
