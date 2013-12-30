//
//  TSEncryptedDatabase.m
//  TextSecureiOS
//
//  Created by Alban Diquet on 11/25/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "TSEncryptedDatabase.h"
#import "TSEncryptedDatabase+Private.h"
#import "TSEncryptedDatabaseError.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "ECKeyPair.h"
#import "FilePath.h"
#import "KeychainWrapper.h"
#import "TSMessage.h"
#import "TSContact.h"
#import "TSThread.h"
#import "TSStorageMasterKey.h"


#import "TSKeyManager.h"


// Reference to the singleton
static TSEncryptedDatabase *SharedCryptographyDatabase = nil;


@implementation TSEncryptedDatabase {

    @protected FMDatabaseQueue *dbQueue;
}

#pragma mark Database instantiation

+(instancetype) database {
  if (!SharedCryptographyDatabase) {
     @throw [NSException exceptionWithName:@"incorrect initialization" reason:@"database must be unlocked or created prior to being able to use this method" userInfo:nil];
  }
  return SharedCryptographyDatabase;
  
}


+(void) databaseErase {
    @synchronized(SharedCryptographyDatabase) {
        
        // Erase the DB file
        [[NSFileManager defaultManager] removeItemAtPath:[FilePath pathInDocumentsDirectory:databaseFileName] error:nil];
        
        // Update the preferences
        [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:kDBWasCreatedBool];
        SharedCryptographyDatabase = nil;
    }
}


+(instancetype) databaseCreateWithPassword:(NSString *)userPassword error:(NSError **)error {

    // Have we created a DB on this device already ?
    if ([TSEncryptedDatabase databaseWasCreated]) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbAlreadyExists];
        }
        return nil;
    }
    
    // 1. Cleanup remnants of a previous DB
    [TSEncryptedDatabase databaseErase];

    // 2. Get storage master key
    NSData *dbMasterKey = [TSStorageMasterKey getStorageMasterKeyWithError:error];
    if (!dbMasterKey) {
        return nil;
    }
    
    // 3. Create the DB and tables
    
    __block BOOL dbInitSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:databaseFileName]];
    [dbQueue inDatabase:^(FMDatabase *db) {
        if(![db setKeyWithData:dbMasterKey]) {
            return;
        }
        if (![db executeUpdate:@"CREATE TABLE persistent_settings (setting_name TEXT UNIQUE,setting_value TEXT)"]) {
            // Happens when the master key is wrong (ie. wrong (old?) encrypted key in the keychain)
            return;
        }
        if (![db executeUpdate:@"CREATE TABLE personal_prekeys (prekey_id INTEGER UNIQUE,public_key TEXT,private_key TEXT, last_counter INTEGER)"]){
            return;
        }
#warning we will want a subtler format than this, prototype message db format
      if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS messages (thread_id INTEGER,message TEXT,sender_id TEXT,recipient_id TEXT, timestamp DATE)"]) {
        return;
      }
      if (![db executeUpdate:@"CREATE TABLE IF NOT EXISTS contacts (registered_phone_number TEXT,relay TEXT, useraddressbookid INTEGER, identitykey TEXT, identityverified INTEGER, supports_sms INTEGER, next_key TEXT)"]){
        return;
      }

      
        dbInitSuccess = YES;
    }
     ];
    
    if (!dbInitSuccess) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbCreationFailed];
        }
        // Cleanup
        [TSEncryptedDatabase databaseErase];
        return nil;
    }
    
    // We have now have an empty DB
    SharedCryptographyDatabase = [[TSEncryptedDatabase alloc] initWithDatabaseQueue:dbQueue];

    // 4. Success - store in the preferences that the DB has been successfully created
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:kDBWasCreatedBool];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return SharedCryptographyDatabase;
}


-(BOOL) storePrekeys:(NSArray*)prekeyArray {
  __block BOOL updateSuccess = NO;
  for(ECKeyPair* keyPair in prekeyArray) {
    [self->dbQueue inDatabase:^(FMDatabase *db) {
      if ([db executeUpdate:@"INSERT OR REPLACE INTO personal_prekeys (prekey_id,public_key,private_key,last_counter) VALUES (?,?,?,?)",[NSNumber numberWithInt:[keyPair prekeyId]], [keyPair publicKey], [keyPair privateKey],[NSNumber numberWithInt:0]]) {
        updateSuccess = YES;
      }
    }];
    if (!updateSuccess) {
      return NO;
      //@throw [NSException exceptionWithName:@"DB creation error" reason:@"could not write prekey" userInfo:nil];
    }
  }
  return updateSuccess;
}


-(BOOL) storePersistentSettings:(NSDictionary*)settingNamesAndValues {
    __block BOOL updateSuccess = YES;
  [self->dbQueue inDatabase:^(FMDatabase *db) {
    for(id settingName in settingNamesAndValues) {
      if (![db executeUpdate:@"INSERT OR REPLACE INTO persistent_settings (setting_name,setting_value) VALUES (?, ?)",settingName,[settingNamesAndValues objectForKey:settingName]]) {
        DLog(@"Error updating DB: %@", [db lastErrorMessage]);
        updateSuccess = NO;
      }
    }
  }];
  return updateSuccess;
}



-(BOOL) storeIdentityKey:(ECKeyPair*)identityKey {

  if(!identityKey) {
    return NO;
  }
    NSDictionary *settings = @{@"identity_key_private": identityKey.privateKey, @"identity_key_public": identityKey.publicKey};
  return [self storePersistentSettings:settings];
}

+(instancetype) databaseUnlockWithPassword:(NSString *)userPassword error:(NSError **)error {
    
    // DB is already unlocked
    if (![TSEncryptedDatabase isLockedOrNotCreated]) {
        return SharedCryptographyDatabase;
    }
    
    // Make sure a DB has already been created
    if (![TSEncryptedDatabase databaseWasCreated]) {
        if (error) {
            *error = [TSEncryptedDatabaseError noDbAvailable];
        }
        return nil;
    }
    
    // Get the DB master key
    NSData *key = [TSStorageMasterKey getStorageMasterKeyWithError:error];
    if (!key) {
        return nil;
    }
    
    // Try to open the DB
    __block BOOL initSuccess = NO;
    FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[FilePath pathInDocumentsDirectory:databaseFileName]];
  
    [dbQueue inDatabase:^(FMDatabase *db) {
        if(![db setKeyWithData:key]) {
            // Supplied password was valid but the master key wasn't !?
            return;
        }
        // Do a test query to make sure the DB is available
        // if this throws an error, the key was incorrect. If it succeeds and returns a numeric value, the key is correct;
        FMResultSet *rset = [db executeQuery:@"SELECT count(*) FROM sqlite_master"];
        if (rset) {
            [rset close];
            initSuccess = YES;
            return;
        }
    }];
    if (!initSuccess) {
        if (error) {
            *error = [TSEncryptedDatabaseError dbWasCorrupted];
        }
        return nil;
    }
    
    // Initialize the DB singleton
    if (!SharedCryptographyDatabase) {
        // First time in the app's lifecycle we're unlocking the DB
        SharedCryptographyDatabase = [[TSEncryptedDatabase alloc] initWithDatabaseQueue:dbQueue];
    }
    else {
        // DB had already been instantiated but was locked
        SharedCryptographyDatabase->dbQueue = dbQueue;
    }
    return SharedCryptographyDatabase;
}


#pragma mark Database state

+(BOOL) databaseWasCreated {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDBWasCreatedBool];
}




+(void) databaseLock {
    
    if (!SharedCryptographyDatabase) {
        @throw [NSException exceptionWithName:@"DB lock failed" reason:@"tried to lock the DB before opening/unlocking it" userInfo:nil];
    }
    
    if ([TSEncryptedDatabase isLockedOrNotCreated]) {
        return;
    }
    
    @synchronized(SharedCryptographyDatabase->dbQueue) {
        // Synchronized in case some other code/thread still has a reference to the DB
        // TODO: Investigate whether this truly closes the DB (in memory)
        [SharedCryptographyDatabase->dbQueue close];
        SharedCryptographyDatabase->dbQueue = nil;
    }
}


+(BOOL) isLockedOrNotCreated {
    if ((!SharedCryptographyDatabase) || (!SharedCryptographyDatabase->dbQueue) ) {
        return YES;
    }
    return NO;
}



#pragma mark Database initialization - private

-(instancetype) initWithDatabaseQueue:(FMDatabaseQueue *)queue {
    if (self = [super init]) {
        self->dbQueue = queue;
    }
    return self;
}


#pragma mark - DB message methods

-(void) storeMessage:(TSMessage*)message {
    [self->dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        NSString *sqlDate = [dateFormatter stringFromDate:message.messageTimestamp];
        
#warning every message is on the same thread! also we only support one recipient
        [db executeUpdate:@"INSERT OR REPLACE INTO messages (thread_id,message,sender_id,recipient_id,timestamp) VALUES (?, ?, ?, ?, ?)",[NSNumber numberWithInt:0],message.message,message.senderId,message.recipientId,sqlDate];
    }];
}

-(NSArray*) getMessagesOnThread:(NSInteger) threadId {
    __block NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    
    [self->dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        FMResultSet  *rs = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM messages WHERE thread_id=%d ORDER BY timestamp", threadId]];

        while([rs next]) {
            NSString* timestamp = [rs stringForColumn:@"timestamp"];
            NSDate *date = [dateFormatter dateFromString:timestamp];
            
            [messageArray addObject:[[TSMessage alloc] initWithMessage:[rs stringForColumn:@"message"] sender:[rs stringForColumn:@"sender_id"] recipients:@[[rs stringForColumn:@"recipient_id"]] sentOnDate:date]];
        }
    }];
    
    return messageArray;
}

// This is only a temporary stub for fetching the message threads
// TODO: return the threads containing participants as well
-(NSArray *) getThreads {
    __block NSMutableArray *threadArray = [[NSMutableArray alloc] init];
    
    [self->dbQueue inDatabase:^(FMDatabase *db) {
        
        NSDateFormatter *dateFormatter = [[self class] sharedDateFormatter];
        FMResultSet  *rs = [db executeQuery:@"SELECT *,MAX(m.timestamp) FROM messages m GROUP BY thread_id ORDER BY timestamp DESC;"];
        
        while([rs next]) {
            NSString* timestamp = [rs stringForColumn:@"timestamp"];
            NSDate *date = [dateFormatter dateFromString:timestamp];
            
            TSThread *messageThread = [[TSThread alloc] init];
            messageThread.latestMessage = [[TSMessage alloc] initWithMessage:[rs stringForColumn:@"message"] sender:[rs stringForColumn:@"sender_id"] recipients:@[[rs stringForColumn:@"recipient_id"]] sentOnDate:date];
            
            [threadArray addObject:messageThread];
        }
    }];

    return threadArray;
}

-(void)storeTSThread:(TSThread*)thread {
    
  [self->dbQueue inDatabase:^(FMDatabase *db) {
    for(TSContact* contact in thread.participants) {
      [contact save];
    }
  }];
}

-(void)findTSContactForPhoneNumber:(NSString*)phoneNumber{
  [self->dbQueue inDatabase:^(FMDatabase *db) {
    
    FMResultSet *searchIfExitInDB = [db executeQuery:@"SELECT registeredID FROM contacts WHERE registered_phone_number = :phoneNumber " withParameterDictionary:@{@"phoneNumber":phoneNumber}];
    
    if ([searchIfExitInDB next]) {
      // That was found :)
      NSLog(@"Entry %@", [searchIfExitInDB stringForColumn:@"useraddressbookid"]);
    }
    
    [searchIfExitInDB close];
  }];
}

-(void)storeTSContact:(TSContact*)contact{
  [self->dbQueue inDatabase:^(FMDatabase *db) {
    
    FMResultSet *searchIfExitInDB = [db executeQuery:@"SELECT registeredID FROM contacts WHERE registered_phone_number = :phoneNumber " withParameterDictionary:@{@"phoneNumber":contact.registeredID}];
      NSDictionary *parameterDictionary = @{@"registeredID": contact.registeredID, @"relay": contact.relay, @"userABID": contact.userABID, @"identityKey": contact.identityKey, @"identityKeyIsVerified":[NSNumber numberWithInt:((contact.identityKeyIsVerified)?1:0)], @"supportsSMS":[NSNumber numberWithInt:((contact.supportsSMS)?1:0)], @"nextKey":contact.nextKey};
      
    
    if ([searchIfExitInDB next]) {
      // the phone number was found, let's now update the contact
      [db executeUpdate:@"UPDATE contacts SET relay = :relay, useraddressbookid :userABID, identitykey = :identityKey, identityverified = :identityKeyIsVerified, supports_sms = :supportsSMS, next_key = :nextKey WHERE registered_phone_number = :registeredID" withParameterDictionary:parameterDictionary];
    }
    else{
      // the contact doesn't exist, let's create him
      [db executeUpdate:@"REPLACE INTO contacts (:registeredID,:relay , :userABID, :identityKey, :identityKeyIsVerified, :supportsSMS, :nextKey)" withParameterDictionary:parameterDictionary];
    }
  }];
}


#pragma mark - shared private objects

+ (NSDateFormatter *)sharedDateFormatter {
    static NSDateFormatter *_sharedFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedFormatter = [[NSDateFormatter alloc] init];
        _sharedFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        _sharedFormatter.timeZone = [NSTimeZone localTimeZone];
    });
    
    return _sharedFormatter;
}

@end
