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
#include "NSData+Base64.h"
#import "TSRegisterPrekeys.h"

#define kKeyForInitBool @"DBWasInit"

// Reference to the singleton
static EncryptedDatabase *SharedCryptographyDatabase = nil;


#pragma mark Private Methods

@interface EncryptedDatabase(Private)

-(instancetype) initWithDatabaseQueue:(FMDatabaseQueue *)queue;

// DB creation helper functions
-(void) generatePersonalPrekeys;
-(void) generateIdentityKey;
+(void) generateAndStoreDatabaseMasterKey:(NSString *)userPassword;

@end


@implementation EncryptedDatabase



#pragma mark DB Instantiation Methods

+(instancetype) database {
  if (!SharedCryptographyDatabase) {
     @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"database must be accessed with password prior to being able to use this method" userInfo:nil];
  }
  return SharedCryptographyDatabase;
  
}


+(instancetype) databaseCreateWithPassword:(NSString *)userPassword {
    // Creating a new DB; this should never fail
    // TODO: Error checking
    
    [EncryptedDatabase generateAndStoreDatabaseMasterKey:userPassword];
    NSData *key = [Cryptography getMasterSecretKey:userPassword];
    // TODO: Create the master secret here
    if(key == nil) {
        @throw [NSException exceptionWithName:@"DB creation failed" reason:@"could not derive the master key" userInfo:nil];
    }
    
    // TODO: Check if a file is already there and erase it
    
    // 1. Create the DB and the tables
    __block BOOL initSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:@"cryptography.db"]];
    [dbQueue inDatabase:^(FMDatabase *db) {
        
        NSData *key = [Cryptography getMasterSecretKey:userPassword];
        if(key == nil) {
            @throw [NSException exceptionWithName:@"DB creation failed" reason:@"could not recover the master key" userInfo:nil];
        }
        
        if(![db setKeyWithData:key]) {
            @throw [NSException exceptionWithName:@"DB creation failed" reason:@"master key was rejected" userInfo:nil];
        }
        
        if (![db executeUpdate:@"CREATE TABLE persistent_settings (setting_name TEXT UNIQUE,setting_value TEXT)"]) {
            @throw [NSException exceptionWithName:@"DB creation failed" reason:@"table creation failed" userInfo:nil];
        }
        if (![db executeUpdate:@"CREATE TABLE personal_prekeys (prekey_id INTEGER UNIQUE,public_key TEXT,private_key TEXT, last_counter INTEGER)"]){
            @throw [NSException exceptionWithName:@"DB creation failed" reason:@"table creation failed" userInfo:nil];
        }
        initSuccess = YES;
    }
     ];
    
    // We have now have an empty DB
    EncryptedDatabase *preFinalDb = [[EncryptedDatabase alloc] initWithDatabaseQueue:dbQueue];

    // 2. Generate and store the identity keys and prekeys
    [preFinalDb generateIdentityKey];
    [preFinalDb generatePersonalPrekeys];
    
    // Send new prekeys to network
    [[TSNetworkManager sharedManager] queueAuthenticatedRequest:[[TSRegisterPrekeys alloc] initWithPrekeyArray:[preFinalDb getPersonalPrekeys] identityKey:[preFinalDb getIdentityKey]] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        switch (operation.response.statusCode) {
            case 200:
                DLog(@"Device registered prekeys");
                break;
                
            default:
                DLog(@"response %d, %@",operation.response.statusCode,operation.response.description);
#warning Add error handling if not able to send the prekeys
                break;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
#warning Add error handling if not able to send the token
        DLog(@"failure %d, %@",operation.response.statusCode,operation.response.description);
    }];
    
    
    // 3. Success
    // Store in the preferences that the DB has been successfully created
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kKeyForInitBool];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Initialize the DB singleton
    SharedCryptographyDatabase = preFinalDb;
    return SharedCryptographyDatabase;
}


+(instancetype) databaseUnlockWithPassword:(NSString *)userPassword error:(NSError **)error {
    // TODO: return errors
    
    // DB is already unlocked
    if (SharedCryptographyDatabase) {
        return SharedCryptographyDatabase;
    }
    
    NSData *key = [Cryptography getMasterSecretKey:userPassword];
    if(key == nil) {
        @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"Could not recover the master key" userInfo:nil];
    }
    
    // Try to open the DB
    __block BOOL initSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:@"cryptography.db"]];
    [dbQueue inDatabase:^(FMDatabase *db) {
        
        NSData *key = [Cryptography getMasterSecretKey:userPassword];
        if(key == nil) {
            @throw [NSException exceptionWithName:@"DB unlock failed" reason:@"could not derive the master key" userInfo:nil];
        }
        
        if(![db setKeyWithData:key]) {
            // Supplied password was invalid
            return;
        }
        
        // Do a test query to make sure the DB is available
        if (![db executeUpdate:@"SELECT * FROM persistent_settings"]) {
            // TODO: Figure out when this can happen and return a helpful error message
            @throw [NSException exceptionWithName:@"DB unlock failed" reason:@"test query failed" userInfo:nil];
        }
        initSuccess = YES;
    }
     ];
    if (!initSuccess) {
        // TODO: error message (+ asking for the password again if pw was wrong)
        return nil;
    }
    
    // Initialize the DB singleton
    SharedCryptographyDatabase = [[EncryptedDatabase alloc] initWithDatabaseQueue:dbQueue];
    return SharedCryptographyDatabase;
}


+(BOOL) dataBaseWasInitialized{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKeyForInitBool];
}


#pragma mark DB Creation Private Methods

-(instancetype) initWithDatabaseQueue:(FMDatabaseQueue *)queue {
    if (self = [super init]) {
        self.dbQueue = queue;
    }
    return self;
}


-(void) generateIdentityKey {
    /*
     An identity key is an ECC key pair that you generate at install time. It never changes, and is used to certify your identity (clients remember it whenever they see it communicated from other clients and ensure that it's always the same).
     
     In secure protocols, identity keys generally never actually encrypt anything, so it doesn't affect previous confidentiality if they are compromised. The typical relationship is that you have a long term identity key pair which is used to sign ephemeral keys (like the prekeys).
     */
    ECKeyPair *identityKey = [ECKeyPair createAndGeneratePublicPrivatePair:-1];
    
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        BOOL updateResult = NO;
        
        updateResult = [db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?, ?)",@"identity_key_private",[identityKey privateKey]];
        if (updateResult == NO) {
            NSLog(@"Error updating DB: %@", [db lastErrorMessage]);
        }
        updateResult = [db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?, ?)",@"identity_key_public",[identityKey publicKey]];
        if (updateResult == NO) {
            NSLog(@"Error updating DB: %@", [db lastErrorMessage]);
        }
    }];
}


-(void) generatePersonalPrekeys {
    // TODO: Error checking
    
    int numberOfPreKeys = 70;
    NSMutableArray *prekeys = [[NSMutableArray alloc] initWithCapacity:numberOfPreKeys];
    int prekeyCounter = arc4random() % 16777215; // 16777215 is 0xFFFFFF
    
    // Generate keys
    for(int i=0; i<numberOfPreKeys; i++) {
        ECKeyPair *keyPair = [ECKeyPair createAndGeneratePublicPrivatePair:++prekeyCounter];
        [self.dbQueue inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"INSERT OR REPLACE INTO personal_prekeys (prekey_id,public_key,private_key,last_counter) VALUES (?,?,?,?)",[NSNumber numberWithInt:[keyPair prekeyId]], [keyPair publicKey], [keyPair privateKey],[NSNumber numberWithInt:0]];
        }];
    }
}


+(void) generateAndStoreDatabaseMasterKey:(NSString *)userPassword {
    NSData *dbMasterKey = [Cryptography generateRandomBytes:36];
    NSData *encryptedDbMasterKey = [Cryptography AES256Encryption:dbMasterKey withPassword:userPassword];
    
    // TODO: Access the keychain from here ?
    [Cryptography storeEncryptedMasterSecretKey:[encryptedDbMasterKey base64EncodedString]];
}


#pragma mark Keys Fetching Methods

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
