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
#import "KeychainWrapper.h"

#define kKeyForInitBool @"DBWasInit"
#define databaseFileName @"cryptography.db"

// Reference to the singleton
static EncryptedDatabase *SharedCryptographyDatabase = nil;


#pragma mark Private Methods

@interface EncryptedDatabase(Private)

-(instancetype) initWithDatabaseQueue:(FMDatabaseQueue *)queue;

// DB creation helper functions
-(void) generatePersonalPrekeys;
-(void) generateIdentityKey;

@end


@implementation EncryptedDatabase



#pragma mark DB Instantiation Methods

+(instancetype) database {
  if (!SharedCryptographyDatabase) {
     @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"database must be accessed with password prior to being able to use this method" userInfo:nil];
  }
  return SharedCryptographyDatabase;
  
}


+(void) databaseErase {
    // 1. Erase the DB file
    [[NSFileManager defaultManager] removeItemAtPath:[FilePath pathInDocumentsDirectory:databaseFileName] error:nil];
    
    // 2. Erase the DB encryption key from the Keychain
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:encryptedMasterSecretKeyStorageId];
    
}


+(void) databaseLock {
    SharedCryptographyDatabase = nil;
}


+(instancetype) databaseCreateWithPassword:(NSString *)userPassword {
    // Creating a new DB; this should never fail
    // TODO: Error checking and check if a DB is already there
    
    // 1. Generate and store DB encryption key
    NSData *dbMasterKey = [Cryptography generateRandomBytes:36];
    NSData *encryptedDbMasterKey = [Cryptography AES256Encryption:dbMasterKey withPassword:userPassword];
    // TODO: Access the keychain from here
    [Cryptography storeEncryptedMasterSecretKey:[encryptedDbMasterKey base64EncodedString]];
    
    
    // 2. Create the DB and the tables
    __block BOOL initSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:databaseFileName]];
    [dbQueue inDatabase:^(FMDatabase *db) {
        
        if(![db setKeyWithData:dbMasterKey]) {
            @throw [NSException exceptionWithName:@"DB creation failed" reason:@"master key was rejected" userInfo:nil];
        }
        
        if (![db executeUpdate:@"CREATE TABLE persistent_settings (setting_name TEXT UNIQUE,setting_value TEXT)"]) {
            // Happens when the master key is wrong (ie. wrong (old?) encrypted key in the keychain)
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

    // 3. Generate and store the user's identity keys and prekeys
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
    
    
    // 4. Success
    // Store in the preferences that the DB has been successfully created
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kKeyForInitBool];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Initialize the DB singleton
    SharedCryptographyDatabase = preFinalDb;
    return SharedCryptographyDatabase;
}


+(instancetype) databaseUnlockWithPassword:(NSString *)userPassword error:(NSError **)error {
    
    // DB is already unlocked
    if (SharedCryptographyDatabase) {
        return SharedCryptographyDatabase;
    }
    
    NSData *key = [Cryptography getMasterSecretKey:userPassword];
    if(key == nil) {
        // Invalid password
        // TODO: Return a different error if this failed because the encryptedMasterKey was not found in the keychain
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        
        [errorDetail setValue:@"Wrong password" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"textSecure" code:100 userInfo:errorDetail];
        return nil;
    }
    
    // Try to open the DB
    __block BOOL initSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:databaseFileName]];
    [dbQueue inDatabase:^(FMDatabase *db) {
        
        NSData *key = [Cryptography getMasterSecretKey:userPassword];
        if(key == nil) {
            return;
        }
        
        if(![db setKeyWithData:key]) {
            // Supplied password was valid but the master key wasn't !?
            return;
        }
        
        // Do a test query to make sure the DB is available
        if (![db executeQuery:@"SELECT * FROM persistent_settings"]) {
            return;
        }
        initSuccess = YES;
    }
     ];
    if (!initSuccess) {
        @throw [NSException exceptionWithName:@"DB unlock failed" reason:@"DB was corrupted" userInfo:nil];
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
